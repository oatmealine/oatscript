local dump = require('dump')
local xml = require('dromozoa.xml')
local lfs = require('lfs')

-- what makes it all work
package.path = './src/common/?.lua;./src/common/?/init.lua;./src/preprocessor/?.lua;./src/preprocessor/?/init.lua;./?.lua;./?/init.lua'

require('dummy-api')
local internals = require('oatscript-internals')

require('test.main')

lfs.rmdir('dist')
lfs.mkdir('dist')
lfs.mkdir('dist/content')

for filename, entries in pairs(internals.outputs) do
  local outDoc
  if filename == 'items' then
    local out = {}

    for _, item in ipairs(entries) do
      table.insert(
        out,
        xml.element(item.type or 'passive', {
          name = item.name,
          description = item.description or '',
          gfx = item.gfx,
          quality = item.quality,
          tags = table.concat(item.tags or {}, ' '),
          cache = item.stats:toCacheString()
        }, {})
      )
    end

    outDoc = xml.element('items', {gfxroot = 'gfx/items/', version = '1'}, out)
  else
    error('output not supported: ' .. filename)
  end

  local file = io.open('dist/content/' .. filename .. '.xml', 'w')
  if file then
    file:write(xml.encode(outDoc))
    file:close()
  else
    error('i/o error!!')
  end
end

local function copyFile(a, b)
  -- no better way to do this apparently
  infile = io.open(a, 'r')
  instr = infile:read("*a")
  infile:close()

  outfile = io.open(b, 'w')
  outfile:write(instr)
  outfile:close()
end

copyFile('test/main.lua', 'dist/main.lua')
lfs.mkdir('dist/oatscript')
copyFile('src/common/oatscript/init.lua', 'dist/oatscript/init.lua')
lfs.mkdir('dist/oatscript-internals')
copyFile('src/lib/oatscript-internals/init.lua', 'dist/oatscript-internals/init.lua')