describe("ft.parse", function()
  local parse

  before_each(function()
    parse = require("ft.parse")
  end)

  after_each(function()
    package.loaded["ft.parse"] = nil
  end)

  describe("find_ft_tags", function()
    it("finds tags at various positions", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Feature: Login",
        "",
        "  @ft:1",
        "  Scenario: User logs in",
        "    Given a user",
        "",
        "  @ft:12",
        "  Scenario: User logs out",
      })
      local tags = parse.find_ft_tags(buf)
      assert.equals(1, tags[2])
      assert.equals(12, tags[6])
      assert.is_nil(tags[0])
      assert.is_nil(tags[3])
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns empty table for buffer with no tags", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Feature: Login",
        "  Scenario: User logs in",
        "    Given a user",
      })
      local tags = parse.find_ft_tags(buf)
      assert.same({}, tags)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("ignores lines where @ft tag is not alone on the line", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "  @ft:1",
        "  @ft:2 extra text",
        "text @ft:3",
        "  @ft:4",
      })
      local tags = parse.find_ft_tags(buf)
      assert.equals(1, tags[0])
      assert.is_nil(tags[1])
      assert.is_nil(tags[2])
      assert.equals(4, tags[3])
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("find_scenario_at_cursor", function()
    local buf

    before_each(function()
      buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Feature: Login",          -- 1
        "",                         -- 2
        "  @ft:1",                  -- 3
        "  Scenario: User logs in", -- 4
        "    Given a user",         -- 5
        "    When they log in",     -- 6
        "",                         -- 7
        "  @ft:2",                  -- 8
        "  Scenario: User logs out",-- 9
        "    Given a logged in user",-- 10
      })
      vim.api.nvim_set_current_buf(buf)
    end)

    after_each(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("finds tag above cursor", function()
      vim.api.nvim_win_set_cursor(0, { 5, 0 })
      local id = parse.find_scenario_at_cursor(buf)
      assert.equals(1, id)
    end)

    it("finds nearest tag when cursor is in second scenario", function()
      vim.api.nvim_win_set_cursor(0, { 10, 0 })
      local id = parse.find_scenario_at_cursor(buf)
      assert.equals(2, id)
    end)

    it("stops at Feature: line", function()
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      local id = parse.find_scenario_at_cursor(buf)
      assert.is_nil(id)
    end)

    it("returns nil when no tag found", function()
      local empty_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(empty_buf, 0, -1, false, {
        "Some random text",
        "More text",
      })
      vim.api.nvim_set_current_buf(empty_buf)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      local id = parse.find_scenario_at_cursor(empty_buf)
      assert.is_nil(id)
      vim.api.nvim_buf_delete(empty_buf, { force = true })
    end)

    it("returns correct id when cursor is on an @ft tag line", function()
      vim.api.nvim_win_set_cursor(0, { 8, 0 })
      local id = parse.find_scenario_at_cursor(buf)
      assert.equals(2, id)
    end)

    it("returns nil for untagged scenario below a tagged one", function()
      local buf2 = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf2, 0, -1, false, {
        "Feature: Login",              -- 1
        "  @ft:1",                      -- 2
        "  Scenario: User logs in",     -- 3
        "    Given a user",             -- 4
        "",                             -- 5
        "  Scenario: User signs up",    -- 6 (no @ft tag)
        "    Given a new user",         -- 7
      })
      vim.api.nvim_set_current_buf(buf2)
      vim.api.nvim_win_set_cursor(0, { 7, 0 })
      local id = parse.find_scenario_at_cursor(buf2)
      assert.is_nil(id)
      vim.api.nvim_buf_delete(buf2, { force = true })
    end)
  end)

  describe("parse_list_output", function()
    it("parses single row", function()
      local output = "@ft:1   login.ft      User logs in           accepted\n"
      local results = parse.parse_list_output(output)
      assert.equals(1, #results)
      assert.equals(1, results[1].id)
      assert.equals("fts/login.ft", results[1].file)
      assert.equals("User logs in", results[1].name)
      assert.equals("accepted", results[1].status)
    end)

    it("parses multiple rows with varying column widths", function()
      local output = table.concat({
        "@ft:1   login.ft      User logs in           accepted",
        "@ft:12  checkout.ft   User completes order   in-progress",
        "@ft:3   login.ft      User logs out          no-activity",
      }, "\n")
      local results = parse.parse_list_output(output)
      assert.equals(3, #results)
      assert.equals(1, results[1].id)
      assert.equals(12, results[2].id)
      assert.equals("fts/checkout.ft", results[2].file)
      assert.equals("User completes order", results[2].name)
      assert.equals("in-progress", results[2].status)
      assert.equals(3, results[3].id)
      assert.equals("no-activity", results[3].status)
    end)

    it("returns empty table for empty string", function()
      local results = parse.parse_list_output("")
      assert.same({}, results)
    end)

    it("handles multi-word scenario names", function()
      local output = "@ft:7   checkout.ft   User logs payment details   in-progress\n"
      local results = parse.parse_list_output(output)
      assert.equals(1, #results)
      assert.equals("User logs payment details", results[1].name)
      assert.equals("in-progress", results[1].status)
    end)
  end)

  describe("parse_tests_output", function()
    it("parses file:line with function name", function()
      local output = "  handler_test.go:42 TestHandler\n  service_test.go:100 TestService\n"
      local results = parse.parse_tests_output(output)
      assert.equals(2, #results)
      assert.equals("handler_test.go", results[1].file)
      assert.equals(42, results[1].lnum)
      assert.equals("TestHandler", results[1].name)
      assert.equals("service_test.go", results[2].file)
      assert.equals(100, results[2].lnum)
      assert.equals("TestService", results[2].name)
    end)

    it("parses file:line without function name", function()
      local output = "  handler_test.go:42\n"
      local results = parse.parse_tests_output(output)
      assert.equals(1, #results)
      assert.equals("handler_test.go", results[1].file)
      assert.equals(42, results[1].lnum)
      assert.is_nil(results[1].name)
    end)

    it("returns empty table for empty string", function()
      local results = parse.parse_tests_output("")
      assert.same({}, results)
    end)

    it("skips lines that do not match file:line format", function()
      local output = "some header\n  handler_test.go:42\nnot a match\n"
      local results = parse.parse_tests_output(output)
      assert.equals(1, #results)
      assert.equals("handler_test.go", results[1].file)
    end)

    it("handles paths with directories", function()
      local output = "  internal/auth/handler_test.go:15\n"
      local results = parse.parse_tests_output(output)
      assert.equals(1, #results)
      assert.equals("internal/auth/handler_test.go", results[1].file)
      assert.equals(15, results[1].lnum)
    end)
  end)

  describe("find_ft_tag_near_cursor", function()
    it("finds tag on current line", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "func TestLogin(t *testing.T) {",
        "  // @ft:42",
        "  t.Run(\"test\", func(t *testing.T) {",
      })
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      local id = parse.find_ft_tag_near_cursor(buf)
      assert.equals(42, id)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("finds tag on line above cursor", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "// @ft:7",
        "func TestCheckout(t *testing.T) {",
        "  t.Run(\"test\", func(t *testing.T) {",
      })
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      local id = parse.find_ft_tag_near_cursor(buf)
      assert.equals(7, id)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns nil when no tag nearby", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "func TestSomething(t *testing.T) {",
        "  t.Run(\"test\", func(t *testing.T) {",
        "    // no tag here",
      })
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      local id = parse.find_ft_tag_near_cursor(buf)
      assert.is_nil(id)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("scenarios_to_qf_entries", function()
    it("builds quickfix entries from scenarios", function()
      local scenarios = {
        { id = 1, file = "fts/login.ft", name = "User logs in", status = "accepted" },
        { id = 2, file = "fts/checkout.ft", name = "User checks out", status = "ready" },
      }
      local entries = parse.scenarios_to_qf_entries(scenarios)
      assert.equals(2, #entries)
      assert.equals("fts/login.ft", entries[1].filename)
      assert.equals("\\m@ft:1", entries[1].pattern)
      assert.equals("User logs in  accepted", entries[1].text)
    end)

    it("excludes removed scenarios", function()
      local scenarios = {
        { id = 1, file = "fts/login.ft", name = "User logs in", status = "accepted" },
        { id = 2, file = "fts/login.ft", name = "User signs up", status = "removed" },
        { id = 3, file = "fts/checkout.ft", name = "User checks out", status = "accepted" },
      }
      local entries = parse.scenarios_to_qf_entries(scenarios)
      assert.equals(2, #entries)
      assert.equals("1", entries[1].pattern:match("@ft:(%d+)"))
      assert.equals("3", entries[2].pattern:match("@ft:(%d+)"))
    end)

    it("returns empty table when all scenarios are removed", function()
      local scenarios = {
        { id = 1, file = "fts/login.ft", name = "User logs in", status = "removed" },
      }
      local entries = parse.scenarios_to_qf_entries(scenarios)
      assert.same({}, entries)
    end)
  end)
end)
