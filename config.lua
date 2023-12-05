--- @alias OpenKind "telescope" | "split"
-- TODO: implement UI ^

--- @class KillRingConfig
--- @field max_size? integer
--- @field open_kind? OpenKind
--- @field buffer_local? boolean
local M = {}

--- Merges users configuration specified in opts with the default config
--- @param opts? KillRingConfig
--- @return KillRingConfig
function M.get_config(opts)
  local config = M.get_default_config()

  if opts ~= nil then
    for k, v in pairs(opts) do
      config[k] = v
    end
  end

  return config
end

--- @return KillRingConfig
function M.get_default_config()
  return {
    max_size = 10,
    open_kind = "telescope", -- < TODO: implement open UI
    buffer_local = false,
  }
end

return M
