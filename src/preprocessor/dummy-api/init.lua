require 'preprocessor.dummy-api.enums'

local dummy = function() end
local function wrapDummy(...) local args = {...} return function() return table.unpack(args) end end

RegisterMod = function(name, version)
  return {
    AddCallback = dummy,
    HasData = wrapDummy(false),
    LoadData = wrapDummy(''),
    RemoveCallback = dummy,
    RemoveData = dummy,
    SaveData = dummy,
    Name = name
  }
end