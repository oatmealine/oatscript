local self = {}
local shared = {}

local outputs = {}

function shared.output(name, thing)
  if not outputs[name] then outputs[name] = {} end
  table.insert(outputs[name], thing)
end

function shared.getOutputs()
  return outputs
end

return {
  preprocessing = true,
  api = self,
  shared = shared
}