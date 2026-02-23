describe("ft.status", function()
  local status, cli, config
  local notifications

  before_each(function()
    config = require("ft.config")
    config._reset()
    config.setup({})
    cli = require("ft.cli")
    status = require("ft.status")
    notifications = {}
    vim.notify = function(msg, level)
      table.insert(notifications, { msg = msg, level = level })
    end
  end)

  after_each(function()
    package.loaded["ft.status"] = nil
    package.loaded["ft.cli"] = nil
    package.loaded["ft.config"] = nil
    package.loaded["ft.parse"] = nil
    package.loaded["ft.virtual_text"] = nil
  end)

  it("notifies warning when no tag found", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "Feature: Login",
      "  Some text without tags",
    })
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    status.set_status_under_cursor("accepted")

    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.WARN, notifications[1].level)
    assert.truthy(notifications[1].msg:match("No @ft tag found"))

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("notifies error when not in ft project", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "  @ft:1",
      "  Scenario: Test",
      "    Given something",
    })
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_win_set_cursor(0, { 3, 0 })

    -- Stub find_root_for_buffer to return nil
    cli.find_root_for_buffer = function(_) return nil end

    status.set_status_under_cursor("accepted")

    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.ERROR, notifications[1].level)
    assert.truthy(notifications[1].msg:match("Not in an ft project"))

    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
