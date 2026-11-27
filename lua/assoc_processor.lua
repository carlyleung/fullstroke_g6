-- lua/assoc_processor.lua
local core = require("assoc_core")
local shift_alone = false
local assoc_shift_pending = false

local function get_last_utf8_char(s)
  if not s or s == "" then return nil end
  local last = nil
  for _, c in utf8.codes(s) do
    last = utf8.char(c)
  end
  return last
end

local function clear_assoc(ctx)
  core.pending_char = nil
  core.current_char = nil
  if ctx.input == ";" then
    ctx:clear()
  end
end

local function init(env)
  if env.assoc_inited then return end
  env.assoc_inited = true
  local ctx = env.engine.context

  -- 1. 監聽上屏：英文模式下唔觸發聯想
  ctx.commit_notifier:connect(function(c)
    if c:get_option("ascii_mode") then
      core.pending_char = nil
      return
    end
    local text = c:get_commit_text()
    local last_char = get_last_utf8_char(text)
    if last_char and core.get_next_chars(last_char) then
      core.pending_char = last_char
    else
      core.pending_char = nil
    end
  end)

  -- 2. 狀態更新：上屏清空完成後，自動填入 ";" 觸發聯想選單
  ctx.update_notifier:connect(function(c)
    if c:get_option("ascii_mode") then
      clear_assoc(c)
      return
    end
    if core.pending_char and c.input == "" then
      core.current_char = core.pending_char
      core.pending_char = nil
      c.input = ";"
    elseif c.input ~= ";" then
      core.current_char = nil
    end
  end)

  -- 3. 監聽中英文切換：一旦轉去英文模式，立即清走隱藏嘅 ";"
  ctx.option_update_notifier:connect(function(c, name)
    if name == "ascii_mode" and c:get_option("ascii_mode") then
      clear_assoc(c)
    end
  end)
end

local function processor(key, env)
  init(env)

  local ctx = env.engine.context
  local kc = key.keycode
  local is_shift = (kc == 0xffe1 or kc == 0xffe2) -- Shift_L / Shift_R

  -- 處理按鍵放開事件
  if key:release() then
    if is_shift and assoc_shift_pending then
      assoc_shift_pending = false
      if shift_alone then
        shift_alone = false
        clear_assoc(ctx)
        ctx:set_option("ascii_mode", true) -- 直接切換去英文模式
      end
      return 1 -- kAccepted，完全攔截避免干擾 ascii_composer
    end
    return 2 -- kNoop
  end

  -- 處理 Shift 按下事件
  if is_shift then
    if ctx.input == ";" and core.current_char then
      assoc_shift_pending = true
      shift_alone = true
      return 1 -- kAccepted，由本腳本接管今次 Shift 動作
    end
    return 2 -- 非聯想狀態下完全交還畀 ascii_composer 正常切換中英文
  else
    -- 按下其他鍵（例如 Shift+標點 或 Shift+4~9 選字），取消單獨 Shift 標記
    shift_alone = false
  end

  -- Caps Lock (0xffe5) 轉大寫英文前，先清走聯想狀態
  if kc == 0xffe5 and ctx.input == ";" and core.current_char then
    clear_assoc(ctx)
    return 2
  end

  -- 只有當目前正顯示聯想選單（input 為 ";"）時先介入處理
  if ctx.input == ";" and core.current_char then
    -- Enter (0xff0d) / 小鍵盤 Enter (0xff8d)（包括 Shift+Enter / Cmd+Enter）：
    -- 立即清走聯想選單，並直接放行 Enter 畀應用程式
    if kc == 0xff0d or kc == 0xff8d then
      clear_assoc(ctx)
      return 2
    end

    -- 系統快捷鍵（Ctrl / Alt / Cmd）：直接放行唔干擾
    if key:ctrl() or key:alt() or key:super() then
      return 2
    end

    -- Esc (0xff1b)、BackSpace (0xff08)、小鍵盤 0 (0xff9e)、小鍵盤 . (0xff9f)：純粹取消聯想
    if kc == 0xff1b or kc == 0xff08 or kc == 0xff9e or kc == 0xff9f then
      clear_assoc(ctx)
      return 1 -- kAccepted
    end

    -- 可見 ASCII 字元處理（確保 ？ ！ ： 「 」 （ ） 以及 ， 。 等都會先清走聯想再放行）
    if kc >= 0x20 and kc <= 0x7e then
      local ch = string.char(kc)

      -- 1) 直接打六筆碼 (iopkl)：清走 ";" 並放行畀 speller 打新字
      if ch:match("^[iopkl]$") then
        clear_assoc(ctx)
        return 2
      end

      -- 2) 撳數字 1-9 或空白鍵揀聯想字：放行畀 selector 上屏
      if (ch:match("^[1-9]$") or ch == " ") and not key:shift() then
        return 2
      end

      -- 3) 所有標點符號（包括需按 Shift 嘅 ？ ！ ： 「 」 （ ） 以及 ， 。 、 小鍵盤 * 等）：
      --    先清走聯想選單，再放行畀 punctuator 直接打出標點
      clear_assoc(ctx)
      return 2
    end
  end

  return 2 -- kNoop
end

return processor