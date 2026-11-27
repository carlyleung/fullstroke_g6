-- force_weight_sort.lua
local function char_len(s)
  return (utf8 and utf8.len(s)) or #s
end

local function force_weight_sort(input, env)
  local cands = {}
  local puncts = {}
  local limit = 200
  local idx = 0

  for cand in input:iter() do
    if cand.type == "punct" then
      -- 先暫存標點符號，唔好即刻搶先輸出
      table.insert(puncts, cand)
    else
      idx = idx + 1
      table.insert(cands, { cand = cand, idx = idx })
      if #cands >= limit then
        break
      end
    end
  end

  table.sort(cands, function(a, b)
    -- 1. 單字（1 個字元）永遠排喺兩個字或以上前面
    local a_multi = char_len(a.cand.text) >= 2
    local b_multi = char_len(b.cand.text) >= 2
    if a_multi ~= b_multi then
      return not a_multi
    end

    -- 2. 同組別內（單字同單字比、多字詞同多字詞比）按權重高至低排
    if a.cand.quality ~= b.cand.quality then
      return a.cand.quality > b.cand.quality
    end

    -- 3. 權重相同時保留詞庫原本先後次序
    return a.idx < b.idx
  end)

  -- 先輸出聯想字 / 單字候選
  for _, item in ipairs(cands) do
    yield(item.cand)
  end

  -- 再按原本順序輸出標點符號（咁樣「；」會排喺聯想字後面，唔會搶第 1 位）
  for _, p in ipairs(puncts) do
    yield(p)
  end

  -- 剩餘候選直接輸出
  for cand in input:iter() do
    yield(cand)
  end
  local ms = (os.clock() - t0) * 1000
  log.warning(string.format("[PERF] force_weight_sort 耗時: %.3f ms (候選數: %d)", ms, #cands))
end

return force_weight_sort