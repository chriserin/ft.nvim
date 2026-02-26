describe("ft.virtual_text", function()
  local virtual_text, config, cli

  before_each(function()
    config = require("ft.config")
    config._reset()
    config.setup({})
    cli = require("ft.cli")
    virtual_text = require("ft.virtual_text")
  end)

  after_each(function()
    package.loaded["ft.virtual_text"] = nil
    package.loaded["ft.config"] = nil
    package.loaded["ft.cli"] = nil
    package.loaded["ft.parse"] = nil
  end)

  local function make_buffer_with_tags()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "Feature: Login",
      "",
      "  @ft:1",
      "  Scenario: User logs in",
      "    Given a user",
      "",
      "  @ft:2",
      "  Scenario: User logs out",
    })
    return buf
  end

  local function stub_cli_list(scenarios, tested_scenarios)
    cli.list = function(_, filters, callback)
      if filters and vim.tbl_contains(filters, "tested") then
        callback(nil, tested_scenarios or {})
      else
        callback(nil, scenarios)
      end
    end
    cli.find_root_for_buffer = function(_)
      return "/tmp/fake-project"
    end
  end

  it("creates extmarks for matching tags", function()
    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
      { id = 2, file = "login.ft", name = "User logs out", status = "in-progress" },
    })

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals(2, #marks)

    -- First extmark on line 2 (0-indexed) for @ft:1
    assert.equals(2, marks[1][2])
    assert.equals(" accepted", marks[1][4].virt_text[1][1])

    -- Second extmark on line 6 (0-indexed) for @ft:2
    assert.equals(6, marks[2][2])
    assert.equals(" in-progress", marks[2][4].virt_text[1][1])

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("applies correct highlight groups per status", function()
    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
      { id = 2, file = "login.ft", name = "User logs out", status = "in-progress" },
    })

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals("DiagnosticOk", marks[1][4].virt_text[1][2])
    assert.equals("DiagnosticWarn", marks[2][4].virt_text[1][2])

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("uses default highlight for unknown status", function()
    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "unknown-status" },
    })

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals(1, #marks)
    assert.equals("Comment", marks[1][4].virt_text[1][2])

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("appends tested indicator as second chunk", function()
    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
      { id = 2, file = "login.ft", name = "User logs out", status = "in-progress" },
    }, {
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
    })

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals(2, #marks)

    -- @ft:1 is tested — two chunks
    assert.equals(2, #marks[1][4].virt_text)
    assert.equals(" accepted", marks[1][4].virt_text[1][1])
    assert.equals(" tested", marks[1][4].virt_text[2][1])

    -- @ft:2 is not tested — one chunk only
    assert.equals(1, #marks[2][4].virt_text)
    assert.equals(" in-progress", marks[2][4].virt_text[1][1])

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("uses DiagnosticHint for tested highlight", function()
    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
    }, {
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
    })

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals(1, #marks)
    assert.equals("DiagnosticHint", marks[1][4].virt_text[2][2])

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("non-tested scenarios have single chunk only", function()
    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
      { id = 2, file = "login.ft", name = "User logs out", status = "in-progress" },
    }, {})

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals(2, #marks)
    assert.equals(1, #marks[1][4].virt_text)
    assert.equals(1, #marks[2][4].virt_text)

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("skips when virtual_text.enabled = false", function()
    config._reset()
    config.setup({ virtual_text = { enabled = false } })

    local buf = make_buffer_with_tags()
    stub_cli_list({
      { id = 1, file = "login.ft", name = "User logs in", status = "accepted" },
    })

    virtual_text.refresh(buf)

    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, 0, -1, { details = true })
    assert.equals(0, #marks)

    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
