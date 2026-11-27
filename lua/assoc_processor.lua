-- lua/assoc_processor.lua
local core = require("assoc_core")

local function get_last_utf8_char(s)
  if not s or s == "" then return nil end
  local last = nil
  for _, c in utf8.codes(s) do
    last = utf8.char(c)
  end
  return last
end

local function init(env)
  if env.assoc_inited then return end
  env.assoc_inited = true
  local ctx = env.engine.context

  -- 1. 監聽上屏：記錄啱啱上屏嘅最後一個字（唔喺度直接改 input，避免被 Rime 上屏後嘅 clear 洗走）
  ctx.commit_notifier:connect(function(c)
    local text = c:get_commit_text()
    local last_char = get_last_utf8_char(text)
    if last_char and core.get_next_chars(last_char) then
      core.pending_char = last_char
    else
      core.pending_char = nil
    end
  end)

  -- 2. 狀態更新：上屏清空完成後，自動填入 ";" 觸發 assoc_translator 彈出聯想選單
  ctx.update_notifier:connect(function(c)
    if core.pending_char and c.input == "" then
      core.current_char = core.pending_char
      core.pending_char = nil
      c.input = ";"
    elseif c.input ~= ";" then
      core.current_char = nil
    end
  end)
end

local function processor(key, env)
  init(env)

  -- 忽略放開按鍵事件
  if key:release() then
    return 2 -- kNoop
  end

  local ctx = env.engine.context

  -- 只有當目前正顯示聯想選單（input 為 ";"）時先介入處理
  if ctx.input == ";" and core.current_char then
    -- 有組合鍵（Ctrl / Alt / Win）就交畀系統或 key_binder 處理
    if key:ctrl() or key:alt() or key:super() then
      return 2
    end

    local kc = key.keycode

    -- Esc (0xff1b)、BackSpace (0xff08)、小鍵盤 0 (0xff9e)、小鍵盤 . (0xff9f)：取消聯想並食走按鍵，避免誤刪文件文字
    if kc == 0xff1b or kc == 0xff08 or kc == 0xff9e or kc == 0xff9f then
      core.current_char = nil
      ctx:clear()
      return 1 -- kAccepted
    end

    -- Enter (0xff0d / 0xff8d)：取消聯想，避免直接打出一個分號 ";"
    if kc == 0xff0d or kc == 0xff8d then
      core.current_char = nil
      ctx:clear()
      return 1
    end

    -- 可見 ASCII 字元處理
    if kc >= 0x20 and kc <= 0x7e then
      local ch = string.char(kc)

      -- 1) 用戶直接打六筆碼 (iopkl，小鍵盤 78945 經過上面 key_binder 亦會變成 iopkl)：
      --    立即清走 ";" 並放行，等後面嘅 speller 正常打新字
      if ch:match("^[iopkl]$") then
        core.current_char = nil
        ctx:clear()
        return 2
      end

      -- 2) 用戶撳數字 1-9 或空白鍵揀聯想字：放行畀 selector 揀字上屏（上屏後會自動觸發下一輪連鎖聯想）
      if ch:match("^[1-9]$") or ch == " " then
        return 2
      end

      -- 3) 用戶撳其他標點（包括想真係打分號 ";"）：清走聯想狀態再放行，就會正常打出標點
      core.current_char = nil
      ctx:clear()
      return 2
    end
  end

  return 2 -- kNoop
end

return processor