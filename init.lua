local config = require("killring.config")

--- @class KillRing
--- @field config KillRingConfig
--- @field values string[] TODO: make own class for this?
local M = {}

--- @param value string
function M.add_to_kill_ring(value)
  if #M.values < M.config.max_size then
    M.values[#M.values + 1] = value
  else
    for i = #M.values, 2, -1 do
      M.values[i] = M.values[i - 1]
    end
    M.values[1] = value
  end
end

--- @param opts? KillRingConfig
function M.setup(opts)
  M.config = config.get_config(opts)
  M.values = {}

  -- TODO: custom autocommand group
  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() M.add_to_kill_ring(vim.fn.getreg('"')) end
  })
end

return M
