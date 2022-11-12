local mod = RegisterMod('test', 1)

local oatscript = require('oatscript.init')
oatscript.setMod(mod)

function r()
  package.loaded['oatscript.init'] = nil
  package.loaded['oatscript-internals.init'] = nil
end

local Collectible = oatscript.Collectible

local item = Collectible({
  name = "Sad Onion 2",
  type = 'passive',
  description = "it's better...",
  gfx = "sadonion2.png", -- gives you a warning if file doesn't exist
  quality = 2,
  tags = {"tearsup"}
})

-- automatically adds the cache flags
item.stats:addTears(2)
item.stats:addDamage(0.2)

item:on('pickup', function(player)
  player:AddCoins(2)
end)

oatscript.lock()