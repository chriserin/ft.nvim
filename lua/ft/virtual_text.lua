local M = {}

local config = require("ft.config")
local cli = require("ft.cli")
local parse = require("ft.parse")

local ns = vim.api.nvim_create_namespace("ft_virtual_text")

M.ns = ns

function M.refresh(bufnr)
  if not config.get().virtual_text.enabled then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local cwd = cli.find_root_for_buffer(bufnr)
  if not cwd then return end

  cli.list(cwd, function(err, scenarios)
    if err or not scenarios then return end
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    local status_map = {}
    for _, s in ipairs(scenarios) do
      status_map[s.id] = s.status
    end

    local tags = parse.find_ft_tags(bufnr)

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local vt_config = config.get().virtual_text
    for line, id in pairs(tags) do
      local status = status_map[id]
      if status then
        local hl = vt_config.hl[status] or vt_config.hl_default
        vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
          virt_text = { { " " .. status, hl } },
          virt_text_pos = vt_config.position,
          hl_mode = "combine",
        })
      end
    end
  end)
end

return M
