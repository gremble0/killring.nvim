local config = require("killring.config")

--- @class KillRing
--- @field config KillRingConfig
--- @field cur_size integer
--- @field values string[] TODO: make own class for this?
local M = {}

--- @param value string
function M:add_to_kill_ring(value)
  -- rotate killring
  for i = self.cur_size, 2, -1 do
    self.values[i] = self.values[i - 1]
  end
  self.values[1] = value

  if self.cur_size < self.config.max_size then
    self.cur_size = self.cur_size + 1
  end
  print(vim.inspect(self.values))
end

--- @param opts? table<string, any>
function M:setup(opts)
  M.config = config.get_config(opts)
  M.cur_size = 0
  M.values = {}

  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() M:add_to_kill_ring(vim.fn.getreg('"')) end
  })
end

return M
