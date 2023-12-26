local config = require("killring.config")
local buffer_local = require("killring.local")
local global = require("killring.global")

local api = vim.api

---Abstract class for the implementations of the backend for the plugin
---@class KillRingImplementation
---@field get_values fun(): KillRingElement[]
---@field add fun(value: string)
---@field paste_from_index fun(index: integer)

---@class KillRing
---@field config KillRingConfig
---@field implementation KillRingImplementation
local M = {}

-- TODO: cursor is not always at correct position after pasting
-- TODO: move parts of function to UI module
function M.open(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  local catted_values = {}
  local values = M.implementation.get_values()

  for _, value in ipairs(values) do
    local s = ""
    if #value.lines == 1 and value.paste_type == "c" then
      s = value.lines[1]
    else
      for _, line in ipairs(value.lines) do
        s = s .. line .. M.config.line_separator
      end
    end

    catted_values[#catted_values + 1] = s
  end

  pickers.new(opts, {
    prompt_title = "Paste from kill ring",
    finder = finders.new_table {
      results = catted_values,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function ()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        M.implementation.paste_from_index(selection.index)
      end)
      return true
    end
  }):find()
end

---@param opts? KillRingConfig
function M.setup(opts)
  M.config = config.get_config(opts)

  if M.config.buffer_local then
    M.implementation = buffer_local.new(M.config)
  else
    M.implementation = global.new(M.config)
  end

  api.nvim_create_autocmd("TextYankPost", {
    callback = function()
      M.implementation.add(vim.fn.getreg('"'))
    end
  })
end

return M
