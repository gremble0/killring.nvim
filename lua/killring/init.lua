local config = require("killring.config")
local element = require("killring.element")
--TODO: 2 files, global, local

local api = vim.api

---@class KillRing
---@field config KillRingConfig
---@field values KillRingElement[]
local M = {}

---@param value string
function M.add_to_global(value)
  local parsed_value = element.new(value)

  if #M.values < M.config.max_size then
    M.values[#M.values + 1] = parsed_value
  else
    for i = #M.values, 2, -1 do
      M.values[i] = M.values[i - 1]
    end
    M.values[1] = parsed_value
  end
end

---@param value string
function M.add_to_local(value)
  local parsed_value = element.new(value)
  local local_killring = api.nvim_buf_get_var(0, "killring")

  if #local_killring < M.config.max_size then
    local_killring[#local_killring + 1] = parsed_value
  else
    for i = #M.values, 2, -1 do
      local_killring[i] = local_killring[i - 1]
    end
    local_killring[1] = parsed_value
  end

  api.nvim_buf_set_var(0, "killring", local_killring)
end

---@param index integer
function M.paste_from_global_index(index)
  local at_index = M.values[index]
  api.nvim_put(at_index.lines, at_index.paste_type, true, true)
end

function M.paste_from_local_index(index)
  local local_killring = api.nvim_buf_get_var(0, "killring")
  -- print(vim.inspect(local_killring))
  local at_index = local_killring[index]
  api.nvim_put(at_index.lines, at_index.paste_type, true, true)
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
  local values
  if M.config.buffer_local then
    values = api.nvim_buf_get_var(0, "killring")
  else
    values = M.values
  end

  for _, value in ipairs(values) do
    -- catted_values[#catted_values + 1] = value.as_string()
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
        if M.config.buffer_local then
          M.paste_from_local_index(selection.index)
        else
          M.paste_from_global_index(selection.index)
        end
      end)
      return true
    end
  }):find()
end

---@param opts? KillRingConfig
function M.setup(opts)
  M.config = config.get_config(opts)

  if M.config.buffer_local then
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

    api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        M.add_to_local(vim.fn.getreg('"'))
        -- print(vim.inspect(api.nvim_buf_get_var(0, "killring")))
      end
    })
  else
    M.values = {}
    api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        M.add_to_global(vim.fn.getreg('"'))
      end
    })
  end
end

return M
