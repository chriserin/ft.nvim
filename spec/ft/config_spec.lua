describe("ft.config", function()
  local config

  before_each(function()
    config = require("ft.config")
    config._reset()
  end)

  after_each(function()
    package.loaded["ft.config"] = nil
  end)

  it("returns defaults when no opts given", function()
    config.setup({})
    local cfg = config.get()
    assert.is_true(cfg.virtual_text.enabled)
    assert.is_true(cfg.keymaps.enabled)
    assert.is_true(cfg.sync_on_write)
    assert.is_nil(cfg.bin)
    assert.equals("eol", cfg.virtual_text.position)
    assert.equals("Comment", cfg.virtual_text.hl_default)
    assert.equals("DiagnosticOk", cfg.virtual_text.hl["accepted"])
  end)

  it("merges user opts over defaults", function()
    config.setup({ bin = "/usr/local/bin/ft", sync_on_write = false })
    local cfg = config.get()
    assert.equals("/usr/local/bin/ft", cfg.bin)
    assert.is_false(cfg.sync_on_write)
    -- defaults still present
    assert.is_true(cfg.virtual_text.enabled)
  end)

  it("deep-merges nested tables", function()
    config.setup({
      virtual_text = {
        hl = {
          ["custom-status"] = "DiagnosticHint",
        },
      },
    })
    local cfg = config.get()
    -- custom key added
    assert.equals("DiagnosticHint", cfg.virtual_text.hl["custom-status"])
    -- existing defaults preserved
    assert.equals("DiagnosticOk", cfg.virtual_text.hl["accepted"])
    assert.equals("DiagnosticWarn", cfg.virtual_text.hl["in-progress"])
  end)

  it("preserves unspecified defaults", function()
    config.setup({ keymaps = { enabled = false } })
    local cfg = config.get()
    assert.is_false(cfg.keymaps.enabled)
    -- mappings still present from defaults
    assert.equals("ready", cfg.keymaps.mappings["<leader>tr"])
    assert.equals("accepted", cfg.keymaps.mappings["<leader>ta"])
    -- other top-level defaults untouched
    assert.is_true(cfg.virtual_text.enabled)
    assert.is_true(cfg.sync_on_write)
  end)

  it("lazy-initializes with defaults on get() without setup()", function()
    local cfg = config.get()
    assert.is_true(cfg.virtual_text.enabled)
    assert.is_true(cfg.sync_on_write)
  end)
end)
