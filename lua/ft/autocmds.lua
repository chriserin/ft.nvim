local M = {}

local config = require("ft.config")
local cli = require("ft.cli")
local virtual_text = require("ft.virtual_text")

local function sync_and_refresh(bufnr, reload_cmd)
	local cwd = cli.find_root_for_buffer(bufnr)
	if not cwd then
		virtual_text.refresh(bufnr)
		return
	end
	cli.sync(cwd, function(err, _)
		if err then
			virtual_text.refresh(bufnr)
			return
		end
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		vim.api.nvim_buf_call(bufnr, reload_cmd)
		virtual_text.refresh(bufnr)
	end)
end

function M.setup()
	local cfg = config.get()
	local group = vim.api.nvim_create_augroup("FtNvim", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*.ft",
		callback = function(args)
			sync_and_refresh(args.buf, function()
				vim.cmd("checktime")
			end)
		end,
	})

	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		pattern = "*.ft",
		callback = function(args)
			sync_and_refresh(args.buf, function()
				vim.cmd("checktime")
			end)
		end,
	})

	if cfg.sync_on_write then
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = group,
			pattern = "*.ft",
			callback = function(args)
				local view = vim.fn.winsaveview()
				sync_and_refresh(args.buf, function()
					vim.cmd("edit")
					vim.fn.winrestview(view)
				end)
			end,
		})
	end

	if cfg.keymaps.enabled then
		for key, action in pairs(cfg.keymaps.mappings) do
			if action == "find" then
				vim.keymap.set("n", key, function()
					require("ft.picker").pick()
				end, { desc = "ft: list scenarios" })
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = "ft",
			callback = function(args)
				for key, action in pairs(cfg.keymaps.mappings) do
					if action == "goto_test" then
						vim.keymap.set("n", key, function()
							require("ft.status").goto_test_under_cursor()
						end, { buffer = args.buf, desc = "ft: go to test" })
					elseif action ~= "find" and action ~= "goto_scenario" then
						vim.keymap.set("n", key, function()
							require("ft.status").set_status_under_cursor(action)
						end, { buffer = args.buf, desc = "ft: " .. action })
					end
				end
				vim.keymap.set("n", "gd", function()
					require("ft.status").show_history_under_cursor()
				end, { buffer = args.buf, desc = "ft: show history" })
			end,
		})

		vim.api.nvim_create_autocmd("BufEnter", {
			group = group,
			pattern = "*_test.go",
			callback = function(args)
				for key, action in pairs(cfg.keymaps.mappings) do
					if action == "goto_scenario" then
						vim.keymap.set("n", key, function()
							require("ft.status").goto_scenario_under_cursor()
						end, { buffer = args.buf, desc = "ft: go to scenario" })
					end
				end
			end,
		})
	end
end

return M
