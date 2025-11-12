if not _VERSION:find('5.4') then
  error('Lua 5.4 must be enabled in the resource manifest!', 2)
end

local RESOURCE_NAME <const> = GetCurrentResourceName()
local AMBITIONS <const> = 'Ambitions'

if RESOURCE_NAME == AMBITIONS then return end

if GetResourceState(AMBITIONS) ~= 'started' then
  error('^1[' .. RESOURCE_NAME .. ']^0 Ambitions must be started before this resource.', 0)
end

amb = exports[AMBITIONS]:object()