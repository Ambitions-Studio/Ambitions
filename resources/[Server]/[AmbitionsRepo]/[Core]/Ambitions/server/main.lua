--- Start the dynamic sync of the database
local function StartPlayerSync()
    CreateThread(function()
        local CHECK_INTERVAL <const> = 1000
        local SYNC_INTERVAL <const> = 5 * 60 * 1000

        while true do
            while next(ABT.Players) == nil do
                Wait(CHECK_INTERVAL)
            end

            while next(ABT.Players) ~= nil do
                for source, player in pairs(ABT.Players) do
                    if player and player.getCurrentCharacter() then
                        ABT.Player.SavePlayer(source, function(success)
                            if success then
                                ABT.Print.Log(2, "Player data saved for source:", source)
                            else
                                ABT.Print.Log(3, "Failed to save player data for source:", source)
                            end
                        end)
                    end
                end
                Wait(SYNC_INTERVAL)
            end
        end
    end)
end

MySQL.ready(function()
    ABT.Print.Log(2, ('^6[%s - %s]^5 - Framework initialized'):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0), GetResourceMetadata(GetCurrentResourceName(), 'name', 0)))
    print('^6 █████╗ ███╗   ███╗██████╗ ██╗████████╗██╗ █████╗ ███╗  ██╗ ██████╗\n██╔══██╗████╗ ████║██╔══██╗██║╚══██╔══╝██║██╔══██╗████╗ ██║██╔════╝\n███████║██╔████╔██║██████╦╝██║   ██║   ██║██║  ██║██╔██╗██║╚█████╗ \n██╔══██║██║╚██╔╝██║██╔══██╗██║   ██║   ██║██║  ██║██║╚████║ ╚═══██╗\n██║  ██║██║ ╚═╝ ██║██████╦╝██║   ██║   ██║╚█████╔╝██║ ╚███║██████╔╝\n╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝   ╚═╝   ╚═╝ ╚════╝ ╚═╝  ╚══╝╚═════╝ ')

    StartPlayerSync()
end)