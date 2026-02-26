local M = {}

function M.find_ft_tags(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local result = {}
  for i, line in ipairs(lines) do
    local id = line:match("^%s*@ft:(%d+)%s*$")
    if id then
      result[i - 1] = tonumber(id)
    end
  end
  return result
end

function M.find_scenario_at_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] -- 1-based
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)

  for i = #lines, 1, -1 do
    local id = lines[i]:match("^%s*@ft:(%d+)%s*$")
    if id then
      return tonumber(id)
    end
    if lines[i]:match("^%s*Scenario:") then
      if i > 1 then
        local tag_id = lines[i - 1]:match("^%s*@ft:(%d+)%s*$")
        if tag_id then
          return tonumber(tag_id)
        end
      end
      return nil
    end
    if lines[i]:match("^%s*Feature:") then
      return nil
    end
  end
  return nil
end

function M.parse_list_output(stdout)
  local results = {}
  for line in stdout:gmatch("[^\n]+") do
    local id = line:match("^@ft:(%d+)")
    if id then
      local rest = line:match("^@ft:%d+%s+(.*)")
      local file = rest:match("^(%S+)")
      rest = rest:match("^%S+%s+(.*)")
      local name, status = rest:match("^(.-)%s%s+(%S+)%s*$")
      if name and status then
        table.insert(results, {
          id = tonumber(id),
          file = "fts/" .. file,
          name = name,
          status = status,
        })
      end
    end
  end
  return results
end

function M.parse_tests_output(stdout)
  local results = {}
  for line in stdout:gmatch("[^\n]+") do
    local file, lnum, name = line:match("^%s*(.+):(%d+)%s+(%S+)%s*$")
    if not file then
      file, lnum = line:match("^%s*(.+):(%d+)%s*$")
    end
    if file and lnum then
      table.insert(results, { file = file, lnum = tonumber(lnum), name = name })
    end
  end
  return results
end

function M.find_ft_tag_near_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local id = lines[row] and lines[row]:match("@ft:(%d+)")
  if id then return tonumber(id) end
  if row > 1 then
    id = lines[row - 1]:match("@ft:(%d+)")
    if id then return tonumber(id) end
  end
  return nil
end

function M.scenarios_to_qf_entries(scenarios)
  local entries = {}
  for _, s in ipairs(scenarios) do
    if s.status ~= "removed" then
      table.insert(entries, {
        filename = s.file,
        pattern = "\\m@ft:" .. s.id,
        text = s.name .. "  " .. s.status,
      })
    end
  end
  return entries
end

return M
