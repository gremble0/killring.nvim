local config = require("killring.config")
local element = require("killring.element")

---@class KillRing
---@field config KillRingConfig
---@field values KillRingElement[]
local M = {}

---@param value string
function M.add_to_kill_ring(value)
  local parsed_value = element:new(value, M.config.line_separator)

  if #M.values < M.config.max_size then
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

-- TODO: cursor is not always at correct position after pasting
-- TODO: move parts of function to UI module
function M.open(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  local catted_values = {}
  for _, value in ipairs(M.values) do
    catted_values[#catted_values + 1] = value:as_string()
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
        M.paste_from_index(selection.index)
      end)
      return true
    end
  }):find()
end

---@return KillRing
function M.new()
  ---@class KillRing
  local kill_ring = M
  kill_ring.values = {}

  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() kill_ring.add_to_kill_ring(vim.fn.getreg('"')) end
  })

  return kill_ring
end

---@param opts? KillRingConfig
function M.setup(opts)
  M.config = config.get_config(opts)
  M.values = {}

  if M.config.buffer_local then
    vim.api.nvim_create_autocmd("BufNew", {
      callback = function()
        local kill_ring = M.new()
        vim.api.nvim_create_autocmd("TextYankPost", {
          callback = function()
            kill_ring.add_to_kill_ring(vim.fn.getreg('"'))
          end
        })
      end
    })
  else
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        local cur_buf = vim.api.nvim_get_current_buf()
        local buf_killring = vim.api.nvim_buf_get_var(cur_buf, "killring")

        buf_killring[#buf_killring+1] = vim.fn.getreg('"')
        vim.api.nvim_buf_set_var(cur_buf, "killring", buf_killring)
      end
    })
  end
end

return M
