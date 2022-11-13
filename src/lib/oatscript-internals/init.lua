local self = {}
local shared = {}

local mod = m
function self.setMod(m)
  mod = m
end

local outputs = {}

function shared.output(name, thing)
  if not outputs[name] then outputs[name] = {} end
  table.insert(outputs[name], thing)
end

function shared.getOutputs()
  return outputs
end

-- TODO: actual saving logic
local save = {
  room = {},
  run = {},
  level = {},
  persistent = {}
}

local function assertMod()
  if not mod then
    error('mod not found! have you made sure you\'ve called oatscript.setMod?')
  end
end

local function getSubPlayerParent(player)
  local playerHash = GetPtrHash(player)
  for i = 0, Game():GetNumPlayers() - 1 do
    local subPlayer = Isaac.GetPlayer(i)
    if subPlayer and GetPtrHash(subPlayer) == playerHash then
      return subPlayer
    end
  end
end

-- https://github.com/IsaacScript/isaacscript/blob/a6b3725/packages/isaacscript-common/src/functions/playerIndex.ts#L84
local function getPlayerIndex(player)
  local playerToUse = player
  if player:IsSubPlayer() then
    local playerParent = getSubPlayerParent(player)
    if playerParent then
      playerToUse = playerParent
    end
  end

  local rng = playerToUse:GetCollectibleRNG(CollectibleType.COLLECTIBLE_SAD_ONION)
  return rng:GetSeed()
end

---@class PlayerStorage @stores a single value for every single player
---@field default any
---@field _storage table<integer, any>
local playerStorage = {}
function playerStorage:set(player, value)
  self._storage[getPlayerIndex(player)] = value
end
function playerStorage:get(player)
  return self._storage[getPlayerIndex(player)] or self.default
end

local function PlayerStorage(default)
  return setmetatable({_storage = {}, default = default}, {__index = playerStorage})
end

local statSetToPlayerField = {
  speed = 'Speed',
  tears = 'MaxFireDelay',
  damage = 'Damage',
  range = 'TearRange',
  shotSpeed = 'ShotSpeed',
  luck = 'Luck'
}
local statSetToCacheFlag = {
  speed = CacheFlag.CACHE_SPEED,
  tears = CacheFlag.CACHE_FIREDELAY,
  damage = CacheFlag.CACHE_DAMAGE,
  range = CacheFlag.CACHE_RANGE,
  shotSpeed = CacheFlag.CACHE_SHOTSPEED,
  luck = CacheFlag.CACHE_LUCK
}
local statSetTransforms = {
  tears = {
    from = function(fireDelay)
      return 30 / (fireDelay + 1)
    end,
    to = function(tears)
      return math.max(30 / tears - 1, -0.9999)
    end
  }
}
local nullTransform = {
  from = function(...) return ... end,
  to = function(...) return ... end
}

---@param callbacks Callback[]
---@param name string
---@return boolean | Callback
local function anyCallbackExists(callbacks, name)
  for _, v in ipairs(callbacks) do
    if v.name == name then
      return v
    end
  end
  return false
end

---@param callbacks Callback[]
---@param name string
---@return Callback[]
local function getAllCallbacks(callbacks, name)
  local t = {}
  for _, v in ipairs(callbacks) do
    if v.name == name then
      table.insert(t, v)
    end
  end
  return t
end

local function handleFunctionGracefully(func, callbackName, ...)
  local success, result = pcall(func, ...)
  if not success then
    error('error running callback ' .. callbackName .. ': ' .. result)
  else
    return result
  end
end

---@param item Collectible
local function processItem(item)
  item.id = Isaac.GetItemIdByName(item.name)

  mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag)
    for i = 1, player:GetCollectibleNum(item.id) do
      for field in pairs(item.stats.modifiedFields) do
        if cacheFlag == statSetToCacheFlag[field] then
          local playerField = statSetToPlayerField[field]
          local transform = statSetTransforms[field] or nullTransform
          player[playerField] = transform.to(transform.from(player[playerField]) * item.stats[field].multiply + item.stats[field].add)
        end
      end
    end
  end)

  if anyCallbackExists(item._callbacks, 'update') then
    local callbacks = getAllCallbacks(item._callbacks, 'update')
    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
      for _, callback in ipairs(callbacks) do
        handleFunctionGracefully(callback.func, callback.name, player)
      end
    end)
  end

  if anyCallbackExists(item._callbacks, 'pickup') then
    local callbacks = getAllCallbacks(item._callbacks, 'pickup')

    local saveKey = 'item_' .. item.name

    save.run[saveKey] = save.run[saveKey] or {}
    save.run[saveKey].pickedUpCount = PlayerStorage(0)

    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
      local num = player:GetCollectibleNum(item.id)
      local itemDelta = num - save.run[saveKey].pickedUpCount:get(player)
      if itemDelta > 0 then
        for i = 1, itemDelta do
          for _, callback in ipairs(callbacks) do
            handleFunctionGracefully(callback.func, callback.name, player)
          end
        end
      elseif itemDelta < 0 then
        -- TODO: drop callback?
      end
      save.run[saveKey].pickedUpCount:set(player, num)
    end)
  end
end

function self.lock()
  assertMod()
  for outtype, entries in pairs(outputs) do
    if outtype == 'items' then
      for _, item in ipairs(entries) do
        processItem(item)
      end
    end
  end

  -- once we're done, flush to let the garbage collector have a field day
  outputs = {}
end

return {
  preprocessing = false,
  api = self,
  shared = shared
}