local debug = import('config.shared.config_debug')

--- Save all players to the database
function ABT.Player.SavePlayers()
    if debug.Save.DebugSavePlayers then
        ABT.Print.Log(5, 'Saving all players to the database')
    end

    local allPlayers = ABT.Players

    ABT.Print.Log(5, 'All players:', allPlayers)

    if not next(allPlayers) then
        return
    end

    local startTime = os.time()

    for sourceID, isSpawned in pairs(allPlayers) do
        if isSpawned then
            ABT.Player.SavePlayer(sourceID, function(success)
                if not success then
                    ABT.Print.Log(3, 'Failed to save player data for source:', sourceID)
                end

                if debug.Save.DebugSavePlayers then
                    ABT.Print.Log(5, 'Player :', sourceID, ('saved over %s ms'):format(ABT.Math.Round((os.time() - startTime) / 1000000, 3)))
                end
            end)
        end
    end
end