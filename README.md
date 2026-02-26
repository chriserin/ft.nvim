# ft.nvim

Neovim plugin for [ft](https://github.com/chriserin/ft), providing inline status tracking, test navigation, and scenario management for `.ft` feature files.

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Virtual Text](#virtual-text)
- [Keymaps](#keymaps)
- [Commands](#commands)
- [Auto-Sync](#auto-sync)

## Requirements

- Neovim >= 0.11
- [ft](https://github.com/chriserin/ft) CLI on your `PATH`
- An initialized ft project (`ft init`)

## Installation

```lua
-- lazy.nvim
{
  "chriserin/ft.nvim",
  event = { "BufReadPre *.ft", "BufNewFile *.ft" },
  cmd = { "FtSync", "FtFind", "FtList" },
  opts = {},
}
```

## Configuration

All options with their defaults:

```lua
require("ft").setup({
  bin = nil,              -- path to ft binary (default: "ft" from PATH)
  sync_on_write = true,   -- auto-sync when saving .ft files

  virtual_text = {
    enabled = true,
    position = "eol",     -- "eol" or "right_align"
    hl = {
      ["accepted"]    = "DiagnosticOk",
      ["ready"]       = "DiagnosticOk",
      ["in-progress"] = "DiagnosticWarn",
      ["fulfilled"]   = "DiagnosticWarn",
      ["rejected"]    = "DiagnosticError",
      ["modified"]    = "DiagnosticInfo",
    },
    hl_default = "Comment",
    tested_hl = "DiagnosticHint",
  },

  keymaps = {
    enabled = true,
    mappings = {
      ["<leader>tr"] = "ready",
      ["<leader>ta"] = "accepted",
      ["<leader>tj"] = "rejected",
      ["<leader>ff"] = "find",
      ["gt"]         = "goto_test",
      ["gT"]         = "goto_scenario",
    },
  },
})
```

## Virtual Text

Scenario statuses appear as colored inline text next to `@ft:<id>` tags. A `tested` badge is appended for scenarios with linked tests.

```
  @ft:1 accepted tested
  Scenario: User logs in
    Given a registered user
    When they enter valid credentials
    Then they see the dashboard

  @ft:2 in-progress
  Scenario: User logs out
```

Status colors use `Diagnostic*` highlight groups, so they work with any colorscheme. Customize via the `virtual_text.hl` table.

## Keymaps

### Status updates (`.ft` files)

| Keymap | Action |
|--------|--------|
| `<leader>tr` | Mark scenario under cursor as "ready" |
| `<leader>ta` | Mark scenario under cursor as "accepted" |
| `<leader>tj` | Mark scenario under cursor as "rejected" |

Status keymaps are configurable — map any key to any status string via `keymaps.mappings`.

### Navigation

| Keymap | Context | Action |
|--------|---------|--------|
| `gt` | `.ft` files | Jump to linked test(s) for scenario under cursor |
| `gT` | `_test.go` files | Jump from test to its scenario definition |
| `gd` | `.ft` files | Show status history in a split |
| `<leader>ff` | any file | Open scenario finder/picker |

When `gt` finds multiple linked tests, they are loaded into the quickfix list.

## Commands

| Command | Description |
|---------|-------------|
| `:FtSync` | Run `ft sync`, reload the buffer, and refresh virtual text |
| `:FtFind` | Open scenario picker to browse and jump to scenarios |
| `:FtList <status...>` | Open quickfix list filtered by status (prefix with `!` to negate) |

## Auto-Sync

The plugin automatically runs `ft sync` in the background on these events:

- **BufEnter `*.ft`** — syncs and refreshes virtual text when you open or switch to a `.ft` file
- **FocusGained `*.ft`** — syncs when Neovim regains focus (picks up external changes)
- **BufWritePost `*.ft`** — syncs after saving (enabled by `sync_on_write`, which is on by default)

All sync operations are async via `vim.system` and will not block the editor.
