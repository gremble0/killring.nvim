local element = require("killring.element")

---@class KillRingGlobal: KillRingImplementation
---@field values KillRingElement[]
---@field max_size integer
local M = {}

---@param value string
function M.add(value)
  local parsed_value = element.new(value)

  if #M.values < M.max_size then
    M.values[#M.values + 1] = parsed_value
  else
    for i = #M.values, 2, -1 do
      M.values[i] = M.values[i - 1]
    end
    M.values[1] = parsed_value
  end
end

---@param index integer
function M.paste_from_index(index)
  local at_index = M.values[index]
  vim.api.nvim_put(at_index.lines, at_index.paste_type, true, true)
end

---@param config KillRingConfig
---@return KillRingGlobal
function M.new(config)
  M.values = {}
  M.max_size = config.max_size

  return M
end

---@return KillRingElement[]
function M.get_values()
  return M.values
end

return M
