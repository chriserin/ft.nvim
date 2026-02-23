local M = {}

local cli = require("ft.cli")
local config = require("ft.config")

function M.pick()
  local cwd = cli.find_root_for_buffer(0)
  if not cwd then
    vim.notify("Not in an ft project", vim.log.levels.ERROR)
    return
  end

  local ok, _ = pcall(require, "telescope")
  if not ok or not config.get().telescope.enabled then
    return M.fallback_pick(cwd)
  end

  cli.list(cwd, function(err, scenarios)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entry_display = require("telescope.pickers.entry_display")

    local displayer = entry_display.create({
      separator = "  ",
      items = {
        { width = 10 },
        { width = 30 },
        { remaining = true },
      },
    })

    pickers.new({}, {
      prompt_title = "ft scenarios",
      finder = finders.new_table({
        results = scenarios,
        entry_maker = function(entry)
          return {
            value = entry,
            display = function(e)
              return displayer({
                { "@ft:" .. e.value.id, "TelescopeResultsIdentifier" },
                { e.value.file, "TelescopeResultsComment" },
                { e.value.name .. "  " .. e.value.status },
              })
            end,
            ordinal = "@ft:" .. entry.id .. " " .. entry.file .. " "
              .. entry.name .. " " .. entry.status,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            local s = selection.value
            vim.cmd("edit " .. vim.fn.fnameescape(s.file))
            vim.fn.search("@ft:" .. s.id, "w")
          end
        end)
        return true
      end,
    }):find()
  end)
end

function M.fallback_pick(cwd)
  cli.list(cwd, function(err, scenarios)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    vim.ui.select(scenarios, {
      prompt = "ft scenarios",
      format_item = function(s)
        return string.format("@ft:%-4d  %-20s  %s  [%s]", s.id, s.file, s.name, s.status)
      end,
    }, function(choice)
      if choice then
        vim.cmd("edit " .. vim.fn.fnameescape(choice.file))
        vim.fn.search("@ft:" .. choice.id, "w")
      end
    end)
  end)
end

return M
