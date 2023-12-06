---@class KillRingElement
---@field lines string[]
---@field line_separator string
local KillRingElement = {}
KillRingElement.__index = KillRingElement

---@param lines string
---@param line_separator string
---@return KillRingElement
function KillRingElement:new(lines, line_separator)
  local kvalue = setmetatable({
    lines = {},
    line_separator = line_separator,
  }, self)

  for line, _ in lines:gmatch("[^\n\r]+") do
    table.insert(kvalue.lines, line)
  end

  return kvalue
end

---Concatenates the lines in self.lines into one string separated by config.line_separator
---@return string
function KillRingElement:as_string()
  if #self.lines == 1 then
    return self.lines[1]
  end

  local s = ""
  for _, line in ipairs(self.lines) do
    s = s .. line .. self.line_separator
  end

  return s
end

---@return string[]
function KillRingElement:as_string_array()
  return self.lines
end

---@return integer
function KillRingElement:length()
  return #self.lines
end

return KillRingElement
