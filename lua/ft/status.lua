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

function M.show_history_under_cursor()
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

  cli.show_history(cwd, id, function(err, output)
    if err then
      vim.notify("ft show --history failed: " .. err, vim.log.levels.ERROR)
      return
    end

    local lines = vim.split(output, "\n", { trimempty = true })
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
    vim.bo[scratch].buftype = "nofile"
    vim.bo[scratch].modifiable = false
    vim.bo[scratch].bufhidden = "wipe"

    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, scratch)

    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = scratch,
      once = true,
      callback = function()
        if vim.api.nvim_buf_is_valid(scratch) then
          vim.api.nvim_buf_delete(scratch, { force = true })
        end
      end,
    })
  end)
end

function M.goto_test_under_cursor()
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

  cli.tests(cwd, id, function(err, stdout)
    local results = parse.parse_tests_output(stdout or "")
    if err or #results == 0 then
      vim.notify("no linked tests for @ft:" .. id, vim.log.levels.INFO)
    elseif #results == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(results[1].file))
      local line_count = vim.api.nvim_buf_line_count(0)
      vim.api.nvim_win_set_cursor(0, { math.min(results[1].lnum, line_count), 0 })
    else
      local entries = {}
      for _, r in ipairs(results) do
        table.insert(entries, {
          filename = r.file,
          lnum = r.lnum,
          text = r.name or ("@ft:" .. id),
        })
      end
      vim.fn.setqflist(entries)
      vim.cmd("copen")
    end
  end)
end

function M.goto_scenario_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local id = parse.find_ft_tag_near_cursor(bufnr)

  if not id then
    vim.notify("No @ft tag found", vim.log.levels.WARN)
    return
  end

  local cwd = cli.find_root_for_buffer(bufnr)
  if not cwd then
    vim.notify("Not in an ft project", vim.log.levels.ERROR)
    return
  end

  local pattern = "@ft:" .. id
  local fts_dir = cwd .. "/fts"
  local ft_files = vim.fn.glob(fts_dir .. "/*.ft", false, true)

  for _, file in ipairs(ft_files) do
    local lines = vim.fn.readfile(file)
    for lnum, line in ipairs(lines) do
      if line:match("^%s*@ft:" .. id .. "%s*$") then
        vim.cmd("edit " .. vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        return
      end
    end
  end

  vim.notify("scenario @ft:" .. id .. " not found in fts/", vim.log.levels.WARN)
end

return M
