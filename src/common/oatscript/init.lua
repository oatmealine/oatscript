local self = {}
local internals = require('oatscript-internals.init')

local preprocessing = internals.preprocessing

local mod
function self.setMod(m)
  mod = m
  if not preprocessing then
    internals.api.setMod(m)
  end
end

---@class MAD @represends a Multiply, then ADd operation
---@field add number
---@field multiply number
local madMeta = {}
function madMeta:applyAdd(a)
  self.add = self.add + a
end
function madMeta:applyMultiply(a)
  self.multiply = self.multiply * a
end
---@return MAD
local function MAD(multiply, add)
  return setmetatable({
    add = add,
    multiply = multiply
  }, {__index = madMeta})
end

local statSetEquivs = {
  shotSpeed = 'shotspeed',
  tears = 'firedelay'
}

---@class StatSet @represents a set of stat transformations
---@field _ref Collectible
---@field speed MAD
---@field tears MAD
---@field damage MAD
---@field range MAD
---@field shotSpeed MAD
---@field luck MAD
---@field modifiedFields table<string, boolean>
local statSetMeta = {}
function statSetMeta:addSpeed(m)
  self.speed:applyAdd(m)
  self.modifiedFields.speed = true
end
function statSetMeta:addTears(m)
  self.tears:applyAdd(m)
  self.modifiedFields.tears = true
end
function statSetMeta:addDamage(m)
  self.damage:applyAdd(m)
  self.modifiedFields.damage = true
end
function statSetMeta:addRange(m)
  self.range:applyAdd(m)
  self.modifiedFields.range = true
end
function statSetMeta:addShotSpeed(m)
  self.shotSpeed:applyAdd(m)
  self.modifiedFields.shotSpeed = true
end
function statSetMeta:addLuck(m)
  self.luck:applyAdd(m)
  self.modifiedFields.luck = true
end
function statSetMeta:toCacheString()
  local cache = {}
  for f in pairs(self.modifiedFields) do
    if statSetEquivs[f] then
      table.insert(cache, statSetEquivs[f])
    else
      table.insert(cache, f)
    end
  end
  return table.concat(cache, ' ')
end

---@return StatSet
local function StatSet()
  return setmetatable({
    speed = MAD(1, 0),
    tears = MAD(1, 0),
    damage = MAD(1, 0),
    range = MAD(1, 0),
    shotSpeed = MAD(1, 0),
    luck = MAD(1, 0),
    modifiedFields = {}
  }, {__index = statSetMeta})
end

---@class Callback
---@field name string
---@field func function
---@field args any[]

---@class Collectible @represents a Collectible
---@field name string
---@field description string
---@field gfx string
---@field quality number
---@field tags string[]
---@field stats StatSet
---@field id integer?
---@field _callbacks table<string, Callback>
local collectible = {}

function collectible:on(callback, func, ...)
  table.insert(self._callbacks, {
    name = callback,
    func = func,
    args = {...}
  })
end

local collectibleMeta = {}
collectibleMeta.__index = collectible

---@return Collectible
function self.Collectible(prop)
  if not type(prop) == 'table' then error('expected table, got a.. ' .. type(prop) .. '??', 2) end
  if not prop.name then error('cannot operate on an item without a name', 2) end

  prop.stats = StatSet()
  prop._callbacks = {}

  local this = setmetatable(prop, collectibleMeta)

  internals.shared.output('items', this)

  return this
end

function self.lock()
  if not preprocessing then
    internals.api.lock()
  end
end

return self