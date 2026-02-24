local M = {}

local config = require("ft.config")
local cli = require("ft.cli")
local virtual_text = require("ft.virtual_text")

function M.setup()
	local cfg = config.get()
	local group = vim.api.nvim_create_augroup("FtNvim", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*.ft",
		callback = function(args)
			virtual_text.refresh(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		pattern = "*.ft",
		callback = function(args)
			local cwd = cli.find_root_for_buffer(args.buf)
			if not cwd then
				return
			end
			cli.sync(cwd, function(err, _)
				if err then
					return
				end
				if not vim.api.nvim_buf_is_valid(args.buf) then
					return
				end
				vim.api.nvim_buf_call(args.buf, function()
					vim.cmd("checktime")
				end)
				virtual_text.refresh(args.buf)
			end)
		end,
	})

	if cfg.sync_on_write then
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = group,
			pattern = "*.ft",
			callback = function(args)
				local view = vim.fn.winsaveview()
				local cwd = cli.find_root_for_buffer(args.buf)
				if not cwd then
					return
				end
				cli.sync(cwd, function(err, _)
					if err then
						return
					end
					if not vim.api.nvim_buf_is_valid(args.buf) then
						return
					end
					vim.api.nvim_buf_call(args.buf, function()
						vim.cmd("edit")
						vim.fn.winrestview(view)
					end)
					virtual_text.refresh(args.buf)
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
					if action ~= "find" then
						vim.keymap.set("n", key, function()
							require("ft.status").set_status_under_cursor(action)
						end, { buffer = args.buf, desc = "ft: " .. action })
					end
				end
			end,
		})
	end
end

return M
