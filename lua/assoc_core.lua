-- lua/assoc_core.lua
local M = {
  map = {},
  pending_char = nil,
  current_char = nil,
  loaded = false,
}

local function add_word(word, weight)
  if not word or word == "" then return end
  local len = utf8.len(word)
  if not len or len < 2 then return end

  local chars = {}
  for _, c in utf8.codes(word) do
    table.insert(chars, utf8.char(c))
  end

  -- 拆解相鄰字對（例如「我們」會建立「我 -> 們」，3字詞會建立連鎖）
  for i = 1, #chars - 1 do
    local k = chars[i]
    local v = chars[i + 1]
    if not M.map[k] then M.map[k] = {} end
    local old_w = M.map[k][v] or 0
    if weight > 1 then
      M.map[k][v] = math.max(old_w, weight)
    else
      M.map[k][v] = old_w + 1
    end
  end
end

function M.load()
  if M.loaded then return end
  M.loaded = true
  local user_dir = rime_api.get_user_data_dir()

  -- 1. 讀取獨立詞庫 lua/assoc_words.txt
  local f1 = io.open(user_dir .. "/lua/assoc_words.txt", "r")
  if f1 then
    for line in f1:lines() do
      line = line:gsub("\r$", "")
      if line ~= "" and not line:match("^#") then
        local word, w = line:match("^([^\t]+)\t?(%d*)")
        add_word(word, tonumber(w) or 1)
      end
    end
    f1:close()
  end

  -- 2. 同時讀取 liubi.dict.yaml 入面日後新增嘅 2 字以上詞組
  local f2 = io.open(user_dir .. "/liubi.dict.yaml", "r")
  if f2 then
    local in_body = false
    for line in f2:lines() do
      line = line:gsub("\r$", "")
      if line == "..." then
        in_body = true
      elseif in_body and line ~= "" and not line:match("^#") then
        local word, _, w = line:match("^([^\t]+)\t([^\t]+)\t?(%d*)")
        add_word(word, tonumber(w) or 1)
      end
    end
    f2:close()
  end

  -- 預先按權重由高至低排好序
  for k, next_table in pairs(M.map) do
    local list = {}
    for ch, w in pairs(next_table) do
      table.insert(list, { char = ch, weight = w })
    end
    table.sort(list, function(a, b)
      if a.weight ~= b.weight then
        return a.weight > b.weight
      end
      return a.char < b.char
    end)
    M.map[k] = list
  end
end

function M.get_next_chars(ch)
  M.load()
  return M.map[ch]
end

return M