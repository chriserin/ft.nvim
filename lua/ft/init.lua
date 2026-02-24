local M = {}

function M.setup(opts)
  require("ft.config").setup(opts)

  vim.filetype.add({ extension = { ft = "ft" } })
  vim.treesitter.language.register("gherkin", "ft")

  vim.api.nvim_create_user_command("FtSync", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local view = vim.fn.winsaveview()
    local cli = require("ft.cli")
    local cwd = cli.find_root_for_buffer(bufnr)
    if not cwd then
      vim.notify("Not in an ft project", vim.log.levels.ERROR)
      return
    end
    cli.sync(cwd, function(err, output)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end
      vim.notify(vim.trim(output), vim.log.levels.INFO)
      if not vim.api.nvim_buf_is_valid(bufnr) then return end
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match("%.ft$") then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("edit")
          vim.fn.winrestview(view)
        end)
        require("ft.virtual_text").refresh(bufnr)
      end
    end)
  end, { desc = "Run ft sync" })

  vim.api.nvim_create_user_command("FtList", function()
    require("ft.picker").pick()
  end, { desc = "List scenarios" })

  vim.api.nvim_create_user_command("FtStatus", function(cmd_opts)
    local status_filter = vim.trim(cmd_opts.args)
    if status_filter == "" then
      vim.notify("Usage: :FtStatus <status>", vim.log.levels.ERROR)
      return
    end
    local cli = require("ft.cli")
    local cwd = cli.find_root_for_buffer(0)
    if not cwd then
      vim.notify("Not in an ft project", vim.log.levels.ERROR)
      return
    end
    cli.list(cwd, function(err, scenarios)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end
      local matched = require("ft.parse").filter_by_status(scenarios, status_filter)
      local entries = {}
      for _, s in ipairs(matched) do
        table.insert(entries, {
          filename = s.file,
          pattern = "\\m@ft:" .. s.id,
          text = s.name .. "  " .. s.status,
        })
      end
      if #entries == 0 then
        vim.notify("No scenarios match \"" .. status_filter .. "\"", vim.log.levels.INFO)
        return
      end
      vim.fn.setqflist(entries, "r")
      vim.cmd("copen")
    end)
  end, { nargs = "?", desc = "List scenarios by status in quickfix" })

  require("ft.autocmds").setup()
end

return M
