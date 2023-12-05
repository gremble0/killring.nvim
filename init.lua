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

function M.paste_from_kill_ring(opts) -- TODO: move parts of function to UI module
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  pickers.new(opts, {
    prompt_title = "Paste from kill ring",
    finder = finders.new_table {
      results = M.values,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function ()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_put({ selection[1] }, "l", true, true)
      end)
      return true
    end
  }):find()
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
