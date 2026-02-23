rockspec_format = "3.0"
package = "ft.nvim"
version = "scm-1"

source = {
  url = "git+https://github.com/chriserin/ft.nvim.git",
}

dependencies = {
  "lua >= 5.1",
}

test_dependencies = {
  "nlua",
  "busted",
}

build = {
  type = "builtin",
}

test = {
  type = "busted",
}
