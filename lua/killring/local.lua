local element = require("killring.element")

---@class KillRingLocal
---@field max_size integer
local M = {}

local api = vim.api

---@param value string
function M.add(value)
  local parsed_value = element.new(value)
  local local_killring = api.nvim_buf_get_var(0, "killring")

  if #local_killring < M.max_size then
    local_killring[#local_killring + 1] = parsed_value
  else
    for i = #local_killring, 2, -1 do
      local_killring[i] = local_killring[i - 1]
    end
    local_killring[1] = parsed_value
  end

  api.nvim_buf_set_var(0, "killring", local_killring)
end

function M.paste_from_index(index)
  local local_killring = api.nvim_buf_get_var(0, "killring")
  local at_index = local_killring[index]
  api.nvim_put(at_index.lines, at_index.paste_type, true, true)
end

---@param config KillRingConfig
---@return KillRingLocal
function M.new(config)
  M.max_size = config.max_size

  -- Suboptimal as this will be called more often than necessary, but no
  -- autocmds fit the needs of this plugin
  api.nvim_create_autocmd("BufWinEnter", {
    callback = function()
      local is_set, _ = pcall(function()
        api.nvim_buf_get_var(0, "killring")
      end)

      if not is_set then
        api.nvim_buf_set_var(0, "killring", {})
      end
    end
  })

  return M
end
--
---@return KillRingElement[]
function M.get_values()
  return api.nvim_buf_get_var(0, "killring")
end

return M
