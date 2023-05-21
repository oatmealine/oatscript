#!/bin/env lua

local argparse = require('argparse')
local dump = require('dump')
local xml = require('dromozoa.xml')
local lfs = require('lfs')
local inotify = require('inotify')
local term = require('term')
local colors = term.colors

local parser = argparse()
  :name('oatscript')
  :epilog('https://github.com/oatmealine/oatscript')
  :add_complete()

local build = parser:command('build b')
build:argument('directory')
  :default('test')

local watch = parser:command('watch w')
watch:argument('directory')
  :default('test')

local set = parser:command('set')
set:argument('what')
set:argument('new')
parser:command('get')
  :argument('what')

local args = parser:parse()

local settings = {}

local function build(dir)
  io.write('building...')

  -- what makes it all work
  local oldPackagePath = package.path
  local oldPrint = print
  package.path = './src/common/?.lua;./src/common/?/init.lua;./src/preprocessor/?.lua;./src/preprocessor/?/init.lua;./?.lua;./?/init.lua'
  print = function() end

  require('dummy-api')
  local internals = require('oatscript-internals')
  require('test.main')

  package.path = oldPackagePath
  print = oldPrint

  package.preload['dummy-api'] = nil
  package.preload['test.main'] = nil
  package.preload['oatscript-internals'] = nil

  lfs.mkdir('dist')
  lfs.mkdir('dist/content')

  for filename, entries in pairs(internals.shared.getOutputs()) do
    local outDoc
    if filename == 'items' then
      local out = {}

      for _, item in ipairs(entries) do
        table.insert(
          out,
          xml.element(item.type or 'passive', {
            name = item.name,
            gfx = item.gfx,
            description = item.description or '',
            tags = table.concat(item.tags or {}, ' '),
            cache = item.stats:toCacheString(),

            hearts = item.hearts,
            maxhearts = item.maxhearts,
            keys = item.keys,
            coins = item.coins,
            bombs = item.bombs,
            achievement = item.achievement,
            special = item.special,
            maxcharges = item.maxcharges,
            hidden = item.hidden,
            soulhearts = item.soulhearts,
            devilprice = item.devilprice,
            blackhearts = item.blackhearts,
            addcostumeonpickup = item.addcostumeonpickup,
            cooldown = item.cooldown,
            persistent = item.persistent,
            quality = item.quality,
            passivecache = item.passivecache,
            chargetype = item.chargetype,
            initcharge = item.initcharge,
            shopprice = item.shopprice,
            discharged = item.discharged,
            craftquality = item.craftquality
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

  os.execute('cp -r test/* dist/')
  os.execute('rm -r dist/oatscript')
  os.execute('cp -r src/common/oatscript dist/oatscript')
  os.execute('rm -r dist/oatscript-internals')
  os.execute('cp -r src/lib/oatscript-internals dist/')

  term.cursor.goleft(100)
  io.write('building... ' .. colors.green .. 'done!' .. colors.reset .. '\n')
end

if args.set then
  if not settings[args.what] then
    print('no such setting: ' .. args.what)
    os.exit(0)
  end
  settings[args.what] = args.new
  print(args.what .. ' = ' .. args.new)
elseif args.get then
  if not settings[args.what] then
    print('no such setting: ' .. args.what)
    os.exit(0)
  end
  print(args.what .. ' = ' .. dump(settings[args.what]))
elseif args.build then
  io.write('\n')
  build(args.directory)
elseif args.watch then
  local handle = inotify.init()

  local flags = inotify.IN_CREATE | inotify.IN_MOVE | inotify.IN_CLOSE_WRITE

  handle:addwatch(args.directory, flags)
  handle:addwatch('src/common/oatscript', flags)
  handle:addwatch('src/lib/oatscript-internals', flags)
  handle:addwatch('src/preprocessor/dummy-api', flags)
  handle:addwatch('src/preprocessor/oatscript-internals', flags)

  for ev in handle:events() do
    print('build triggered by ' .. ev.name)
    build()
  end
else
  print(dump(args))
end