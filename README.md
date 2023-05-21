# oatscript

> **Note**
> oatscript is in its early prototype stages as of right now. APIs are unstable and support is very limited; proceed with caution.

oatscript is a framework aimed to delete, expunge and otherwise destroy XMLs from your Isaac mods, and benefit you directly from its abstractions and abominations.

## Why

The design thought process is why have something like this:

```xml
<passive name="Sad Onion 2" description="it's better..." gfx="sadonion2.png" quality="2" tags="tearsup">
```
```lua
local item = {}
item.id = Isaac.GetItemById('Sad Onion 2')
```

When you can compact this down when defining the item in Lua rather than in XML:

```lua
local item = Collectible({
  name = "Sad Onion 2",
  description = "it's better...",
  gfx = "sadonion2.png",
  quality = 2,
  tags = {"tearsup"}
})

print(item.id) --> assigned at runtime
```

The moment you want to add a stat to the player with the usual XML workflow, you'll have to delve back into your `items.xml` to add `cache`:
```xml
<passive name="Sad Onion 2" description="it's better..." gfx="sadonion2.png" quality="2" tags="tearsup" cache="firedelay">
```
And then define a callback and do the tears math:
```lua
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag)
  if cacheFlag == CacheFlag.CACHE_FIREDELAY then
    player.MaxFireDelay = fromTears(toTears(player.MaxFireDelay) + 2)
  end
end)
```
But why do this, when you can let the framework do it for you:
```lua
item.stats:addTears(2)
```
The list of end-developer UX improvements goes on and on; but the main goal is to keep things DRY and prioritize making commonly-done practices short and simple.

## How

oatscript runs your mod code through a preprocessor, but doesn't modify it - it runs it as a standard Lua environment, with a dummy API and a different set of oatscript internals to get the data necessary to have encoded in XMLs. In other words, when the preprocessor sees this code:
```lua
local item = Collectible({...})
```
Rather than initializing the item, adding callbacks, etc., the different set of internals will record all necessary metadata, which is then encoded in an XML.

Once the preprocessor step is done, the internals are swapped out for production-ready code which simply gives back the data the mod expects and implements the promised features.

## No, like, how do I run this

You'll need Lua and LuaRocks installed. Run this to install dependencies:
```sh
$ luarocks build --no-project --local ./oatscript-prototype-1.rockspec
```
Then you use the CLI oatscript tool:
```sh
$ ./oatscript.lua build
$ # or
$ lua oatscript.lua build
```
Everything in `test/` will be the input; `dist/` is the output. Currently you cannot run the tool outside of the repository; this will be changed soon enough. (I think you can tell quite clearly by this that it's not quite meant for production use.)

## I don't like your design decisions!

Come talk to me about it! I'm very open to feedback and changing things as people prefer rather than how I prefer it. oatscript lives at [a tiny post](https://discord.com/channels/962027940131008653/1040795686255464538) on the `#hub` channel in the [Modding of Isaac Discord guild](https://discord.gg/pDBw5R5VKZ). Or you can make an issue here. Whichever one you prefer.
