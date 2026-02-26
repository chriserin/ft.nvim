local M = {}
local _config = nil

local defaults = {
	bin = nil,

	virtual_text = {
		enabled = true,
		hl = {
			["accepted"] = "DiagnosticOk",
			["in-progress"] = "DiagnosticWarn",
			["fulfilled"] = "DiagnosticWarn",
			["ready"] = "DiagnosticOk",
			["rejected"] = "DiagnosticError",
			["modified"] = "DiagnosticInfo",
		},
		hl_default = "Comment",
		tested_hl = "DiagnosticHint",
		position = "eol",
	},

	keymaps = {
		enabled = true,
		mappings = {
			["<leader>tr"] = "ready",
			["<leader>ta"] = "accepted",
			["<leader>tj"] = "rejected",
			["<leader>ff"] = "find",
			["gt"] = "goto_test",
			["gT"] = "goto_scenario",
		},
	},

	sync_on_write = true,
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
