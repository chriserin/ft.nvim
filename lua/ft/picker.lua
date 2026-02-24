local M = {}

local cli = require("ft.cli")

function M.pick()
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

    local filtered = {}
    for _, s in ipairs(scenarios) do
      if s.status ~= "removed" then
        table.insert(filtered, {
          text = "@ft:" .. s.id .. " " .. s.name,
          id = s.id,
          file = s.file,
          name = s.name,
          status = s.status,
        })
      end
    end

    local bin = require("ft.config").get().bin or "ft"

    Snacks.picker({
      title = "ft scenarios",
      items = filtered,
      format = function(item)
        return { { item.text } }
      end,
      preview = function(ctx)
        Snacks.picker.preview.cmd({ bin, "show", tostring(ctx.item.id) }, ctx, { cwd = cwd })
      end,
      confirm = function(picker, item)
        picker:close()
        if item then
          vim.cmd("edit " .. vim.fn.fnameescape(item.file))
          vim.fn.search("@ft:" .. item.id, "w")
        end
      end,
    })
  end)
end

return M
