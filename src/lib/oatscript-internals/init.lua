local self = {}

local mod = m
function self.setMod(m)
  mod = m
end

self.outputs = {}

local function assertMod()
  if not mod then
    error('mod not found! have you made sure you\'ve called oatscript.setMod?')
  end
end

local statSetToPlayerField = {
  speed = 'Speed',
  tears = 'MaxFireDelay',
  damage = 'Damage',
  range = 'TearRange',
  shotSpeed = 'ShotSpeed',
  luck = 'Luck'
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

function self.lock()
  print('locking mod registries')
  assertMod()
  for outtype, entries in pairs(self.outputs) do
    print('out type ' .. outtype)
    if outtype == 'items' then
      for _, item in ipairs(entries) do
        ---@type Collectible
        local item = item
        local id = Isaac.GetItemIdByName(item.name)

        print('hewwo item ' .. item.name .. ' (' .. id .. ')')

        mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
          print('cache')
          for i = 1, player:GetCollectibleNum(id) do
            for field in pairs(item.stats.modifiedFields) do
              print(field)
              local playerField = statSetToPlayerField[field]
              local transform = statSetTransforms[field] or nullTransform
              player[playerField] = transform.to(transform.from(player[playerField]) * item.stats[field].multiply + item.stats[field].add)
            end
          end
        end)
      end
    end
  end
end

return {
  preprocessing = false,
  outputs = outputs,
  api = self
}