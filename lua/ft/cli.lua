local M = {}

local config = require("ft.config")

local function find_root(start_path)
  local path = start_path
  while path and path ~= "/" do
    if vim.fn.isdirectory(path .. "/fts") == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return nil
end

local function run(cmd_args, cwd, callback)
  local bin = config.get().bin or "ft"
  local cmd = vim.list_extend({ bin }, cmd_args)

  local ok, err = pcall(vim.system, cmd, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(result.stderr or ("ft exited with code " .. result.code), nil)
      else
        callback(nil, result.stdout)
      end
    end)
  end)
  if not ok then
    vim.schedule(function()
      callback("`" .. bin .. "` not found — is it installed and on PATH?", nil)
    end)
  end
end

function M.find_root_for_buffer(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return find_root(vim.fn.fnamemodify(path, ":h"))
end

function M.sync(cwd, callback)
  run({ "sync" }, cwd, callback)
end

function M.list(cwd, filters, callback)
  local cmd_args = { "list" }
  if filters then
    for _, f in ipairs(filters) do
      if f:sub(1, 1) == "!" then
        table.insert(cmd_args, "--not")
        table.insert(cmd_args, f:sub(2))
      else
        table.insert(cmd_args, f)
      end
    end
  end
  run(cmd_args, cwd, function(err, stdout)
    if err then return callback(err, nil) end
    callback(nil, require("ft.parse").parse_list_output(stdout))
  end)
end

function M.set_status(cwd, id, status, callback)
  run({ "status", tostring(id), status }, cwd, callback)
end

function M.show_history(cwd, id, callback)
  run({ "show", "--history", tostring(id) }, cwd, callback)
end

function M.tests(cwd, id, callback)
  run({ "tests", tostring(id) }, cwd, callback)
end

return M
