-- force_weight_sort.lua（輕量版）
local function force_weight_sort(input, env)
  local cands = {}
  local limit = 50  -- 只處理前 50 個候選，可自行調整

  for cand in input:iter() do
    table.insert(cands, cand)
    if #cands >= limit then
      break
    end
  end

  table.sort(cands, function(a, b)
    return a.quality > b.quality
  end)

  for _, cand in ipairs(cands) do
    yield(cand)
  end

  -- 剩餘候選直接輸出（唔再排序）
  for cand in input:iter() do
    yield(cand)
  end
end

return force_weight_sort
