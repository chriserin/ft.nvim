local M = {}

function M.setup(opts)
  require("ft.config").setup(opts)

  vim.filetype.add({ extension = { ft = "ft" } })
  vim.treesitter.language.register("gherkin", "ft")

  vim.api.nvim_create_user_command("FtSync", function()
    local bufnr = vim.api.nvim_get_current_buf()
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
        end)
        require("ft.virtual_text").refresh(bufnr)
      end
    end)
  end, { desc = "Run ft sync" })

  vim.api.nvim_create_user_command("FtList", function()
    require("ft.telescope").pick()
  end, { desc = "List scenarios" })

  vim.api.nvim_create_user_command("FtStatus", function(cmd_opts)
    local args = vim.split(cmd_opts.args, " ", { trimempty = true })
    if #args < 2 then
      vim.notify("Usage: :FtStatus <id> <status>", vim.log.levels.ERROR)
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local cli = require("ft.cli")
    local cwd = cli.find_root_for_buffer(bufnr)
    if not cwd then
      vim.notify("Not in an ft project", vim.log.levels.ERROR)
      return
    end
    local id = args[1]
    local status_name = table.concat(vim.list_slice(args, 2), " ")
    cli.set_status(cwd, id, status_name, function(err, output)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end
      vim.notify(vim.trim(output), vim.log.levels.INFO)
      if not vim.api.nvim_buf_is_valid(bufnr) then return end
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match("%.ft$") then
        require("ft.virtual_text").refresh(bufnr)
      end
    end)
  end, { nargs = "+", desc = "Set scenario status" })

  require("ft.autocmds").setup()
end

return M
