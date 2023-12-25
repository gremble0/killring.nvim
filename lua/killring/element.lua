---@class KillRingElement
---@field lines string[]
---@field paste_type string
local M = {}

---@param lines string
---@return KillRingElement
function M.new(lines) -- TODO remove line_separator from this class
  ---@class KillRingElement
  local element = {}
  element.lines = {}

  for line, _ in lines:gmatch("[^\n\r]+") do
    element.lines[#element.lines + 1] = line
  end

  if (#element.lines > 1) or (lines:find("\n") and #element.lines == 1) then
    element.paste_type = "l"
  else
    element.paste_type = "c"
  end

  return element
end

return M
