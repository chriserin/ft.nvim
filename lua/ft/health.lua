local M = {}

function M.check()
  vim.health.start("ft.nvim")

  local cfg = require("ft.config").get()
  local bin = cfg.bin or "ft"
  if vim.fn.executable(bin) == 1 then
    vim.health.ok("`" .. bin .. "` found")
  else
    vim.health.error("`" .. bin .. "` not found on PATH")
  end

  local cwd = require("ft.cli").find_root_for_buffer(0)
  if cwd then
    vim.health.ok("`fts/` directory found at " .. cwd)
  else
    vim.health.warn("`fts/` directory not found — run `ft init`")
  end

  if cwd and vim.fn.filereadable(cwd .. "/fts/ft.db") == 1 then
    vim.health.ok("`fts/ft.db` exists")
  elseif cwd then
    vim.health.warn("`fts/ft.db` not found — run `ft init`")
  end

  local ok, _ = pcall(require, "telescope")
  if ok then
    vim.health.ok("telescope.nvim available")
  else
    vim.health.info("telescope.nvim not installed — :FtList will use vim.ui.select")
  end
end

return M
