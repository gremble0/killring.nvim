local config = require("killring.config")

---@class KillRing
---@field config KillRingConfig
---@field values string[][] TODO: make own class for this? (list of values in kill ring, nested array for multiline values)
local M = {}

---@param s string
---@return string[]
function M._split_by_newlines(s) -- TODO: move to separate module
  local lines = {}

  for line, _ in s:gmatch("[^\n\r]+") do
    table.insert(lines, line)
  end

  return lines
end

---@param lines string[]
---@return string
function M._cat_newlines(lines)
  local s = ""

  for _, line in ipairs(lines) do
    s = s .. line .. M.config.line_separator
  end

  return s
end

---@param value string
function M.add_to_kill_ring(value)
  local parsed_value = M._split_by_newlines(value)

  if #M.values < M.config.max_size then
    M.values[#M.values + 1] = parsed_value
  else
    for i = #M.values, 2, -1 do
      M.values[i] = M.values[i - 1]
    end
    M.values[1] = parsed_value
  end
end

function M.paste_from_kill_ring(opts) -- TODO: move parts of function to UI module
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  local catted_values = {}
  for _, value in ipairs(M.values) do
    table.insert(catted_values, M._cat_newlines(value))
  end

  pickers.new(opts, {
    prompt_title = "Paste from kill ring",
    finder = finders.new_table {
      results = catted_values, -- TODO: self and ':' things?
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function ()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_put(M.values[selection.index], "l", true, true)
      end)
      return true
    end
  }):find()
end

---@param opts? KillRingConfig
function M.setup(opts)
  M.config = config.get_config(opts)
  M.values = {}

  -- TODO: custom autocommand group
  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() M.add_to_kill_ring(vim.fn.getreg('"')) end
  })
end

return M
