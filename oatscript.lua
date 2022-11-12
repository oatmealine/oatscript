#!/bin/env lua

local argparse = require('argparse')
local dump = require('dump')

local parser = argparse()
  :name('oatscript')
  :epilog('https://github.com/oatmealine/oatscript')
  :add_complete()

local build = parser:command('build b')
build:argument('directory')

local set = parser:command('set')
set:argument('what')
set:argument('new')
parser:command('get')
  :argument('what')

local args = parser:parse()

local settings = {}

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
else
  print(dump(args))
end