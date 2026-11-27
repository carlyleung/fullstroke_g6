-- lua/assoc_translator.lua
local core = require("assoc_core")

local function translator(input, seg, env)
  if input == ";" and core.current_char then
    local list = core.get_next_chars(core.current_char)
    if list then
      for _, item in ipairs(list) do
        local cand = Candidate("assoc", seg.start, seg._end, item.char, "")
        cand.quality = item.weight
        cand.preedit = "\xe2\x80\x8b"
        yield(cand)
      end
    end
  end
end

return translator