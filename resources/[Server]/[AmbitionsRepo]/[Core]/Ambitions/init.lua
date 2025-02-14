if not _VERSION:find('5.4') then
    error('Lua 5.4 must be enabled in the resource manifest!', 2)
end

local RESOURCE_NAME <const> = GetCurrentResourceName()
local AMBITIONS <const> = 'Ambitions'

if RESOURCE_NAME == AMBITIONS then return end

if GetResourceState(AMBITIONS) ~= 'started' then
    error('^Ambitions must be started before this resource.^0', 0)
end

ABT = exports[AMBITIONS]:object()

if not IsDuplicityVersion() then
    AddEventHandler('ambitions:setPlayerData', function(key, value, oldValue)
        if GetInvokingResource() == RESOURCE_NAME then
            ABT.PlayerData[key] = value
        end
    end)
end

RegisterNetEvent('ambitions:playerLoaded', function(amberPlayer)
    ABT.PlayerLoaded = true
    ABT.PlayerData = amberPlayer
end)

RegisterNetEvent('ambitions:playerUnloaded', function()
    ABT.PlayerLoaded = false
    ABT.PlayerData = {}
end)