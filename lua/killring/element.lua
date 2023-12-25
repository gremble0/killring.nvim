---@class KillRingElement
---@field lines string[]
---@field paste_type string
---@field line_separator string
local KillRingElement = {}
KillRingElement.__index = KillRingElement

---@param lines string
---@param line_separator string
---@return KillRingElement
function KillRingElement:new(lines, line_separator) -- TODO remove line_separator from this class
  local element = setmetatable({
    lines = {},
    line_separator = line_separator,
  }, self)

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

---Concatenates the lines in self.lines into one string separated by self.line_separator
---@return string
function KillRingElement:as_string()
  if #self.lines == 1 and self.paste_type == "c" then
    return self.lines[1]
  end

  local s = ""
  for _, line in ipairs(self.lines) do
    s = s .. line .. self.line_separator
  end

  return s
end

return KillRingElement
