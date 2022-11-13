rockspec_format = "3.0"

package = "oatscript"
version = "prototype-1"
source = {
  url = "git://github.com/oatmealine/oatscript"
}
description = {
  summary = "A Binding of Isaac modding framework designed to eliminate XMLs from existance",
  detailed = [[
    A modding framework for Binding of Isaac designed to
    remove XMLs, upkeep DRY and keep code structure more
    sane and DRY-proof.
  ]],
  homepage = "https://github.com/oatmealine/oatscript",
  license = "LGPL-3.0"
}
dependencies = {
  "lua == 5.3",
  "argparse >= 0.7.1",
  "luafilesystem >= 1.8.0",
  "inotify >= 0.5",
  "lua-term >= 0.7",
  "dump >= 0.1.2",
  "dromozoa-xml >= 1.6"
}
build = {
  type = "builtin",
  modules = {
    oatscript = "oatscript.lua",
  }
}