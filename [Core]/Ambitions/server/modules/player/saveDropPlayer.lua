--- Save Player when he disconnects
---@param reason string The reason of the disconnection
---@return void
AddEventHandler('playerDropped', function(reason)
    local SOURCE <const> = source
    local PLAYER = ABT.GetPlayerFromId(SOURCE)

    if PLAYER then
        TriggerEvent('ambitions:playerDropped', SOURCE, reason)

        ABT.Player.SavePlayer(SOURCE, function(success)
            if not success then
                ABT.Print.Log(3, 'Failed to save player data for source :', SOURCE)
            end
            if not ABT.Players[SOURCE] then
                ABT.Print.Log(3, 'Attempted to remove a non-existent player from the general players list, player source : ', SOURCE)

                return
            end

            ABT.Players[SOURCE] = nil
        end)

        TriggerClientEvent('ambitions:playerUnloaded', SOURCE)
    end
end)

function ABT.GetPlayerFromId(source)
    return ABT.Players[tonumber(source)]
end