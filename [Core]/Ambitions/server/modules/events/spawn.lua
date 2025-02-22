RegisterNetEvent('ambitions:server:onPlayerSpawn', function(source)
    if not source then
        ABT.Print.Log(3, 'Failed to retrieve source for onPlayerSpawn event')
        return
    end

    if ABT.Players[source] then
        ABT.Print.Log(3, 'Player already exists in ABT.Players:', source)
        return
    end

    ABT.Players[source].spawned = true
end)
