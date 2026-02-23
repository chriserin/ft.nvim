describe("ft.cli", function()
  local cli

  before_each(function()
    cli = require("ft.cli")
  end)

  after_each(function()
    package.loaded["ft.cli"] = nil
    package.loaded["ft.config"] = nil
    package.loaded["ft.parse"] = nil
  end)

  describe("find_root_for_buffer", function()
    it("finds root when fts/ exists", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir .. "/fts", "p")
      local ftfile = tmpdir .. "/fts/login.ft"
      vim.fn.writefile({ "Feature: Login" }, ftfile)

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, ftfile)

      local root = cli.find_root_for_buffer(buf)
      assert.equals(tmpdir, root)

      vim.api.nvim_buf_delete(buf, { force = true })
      vim.fn.delete(tmpdir, "rf")
    end)

    it("returns nil when no fts/ found", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")
      local somefile = tmpdir .. "/test.txt"
      vim.fn.writefile({ "hello" }, somefile)

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, somefile)

      local root = cli.find_root_for_buffer(buf)
      assert.is_nil(root)

      vim.api.nvim_buf_delete(buf, { force = true })
      vim.fn.delete(tmpdir, "rf")
    end)
  end)
end)
