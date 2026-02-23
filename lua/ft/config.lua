local M = {}
local _config = nil

local defaults = {
  bin = nil,

  virtual_text = {
    enabled = true,
    hl = {
      ["accepted"] = "DiagnosticOk",
      ["in-progress"] = "DiagnosticWarn",
      ["done"] = "DiagnosticWarn",
      ["ready"] = "DiagnosticOk",
    },
    hl_default = "Comment",
    position = "eol",
  },

  keymaps = {
    enabled = true,
    mappings = {
      ["<leader>tr"] = "ready",
      ["<leader>ta"] = "accepted",
      ["<leader>ff"] = "list",
    },
  },

  sync_on_write = true,
  telescope = { enabled = true },
}

function M.setup(opts)
  _config = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get()
  if not _config then
    M.setup({})
  end
  return _config
end

function M._reset()
  _config = nil
end

return M
