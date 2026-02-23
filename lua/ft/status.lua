local M = {}

local parse = require("ft.parse")
local cli = require("ft.cli")
local virtual_text = require("ft.virtual_text")

function M.set_status_under_cursor(status_name)
  local bufnr = vim.api.nvim_get_current_buf()
  local id = parse.find_scenario_at_cursor(bufnr)

  if not id then
    vim.notify("No @ft tag found — run :FtSync", vim.log.levels.WARN)
    return
  end

  local cwd = cli.find_root_for_buffer(bufnr)
  if not cwd then
    vim.notify("Not in an ft project", vim.log.levels.ERROR)
    return
  end

  cli.set_status(cwd, id, status_name, function(err, output)
    if err then
      vim.notify("ft status failed: " .. err, vim.log.levels.ERROR)
      return
    end
    vim.notify(vim.trim(output), vim.log.levels.INFO)
    virtual_text.refresh(bufnr)
  end)
end

return M
