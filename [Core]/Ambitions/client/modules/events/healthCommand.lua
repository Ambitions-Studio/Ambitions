RegisterNetEvent('ambitions:command:healPlayer')
AddEventHandler('ambitions:command:healPlayer', function()
    local player = PlayerPedId()
    SetEntityHealth(player, GetEntityMaxHealth(player))
end)

RegisterNetEvent('ambitions:command:killPlayer', function()
    local player = PlayerPedId()
    SetEntityHealth(player, 0)
    SetPedArmour(player, 0)
end)

RegisterNetEvent('ambitions:character:updateHealth', function(health)
    local player = PlayerPedId()
    SetEntityHealth(player, health)
end)

RegisterNetEvent('ambitions:needs:add', function(name, value)
    local player = ABT.GetPlayerData(PlayerPedId())
    local character = player.getCurrentCharacter()

    character.needs.addNeed(name, value)
end)

RegisterNetEvent('ambitions:needs:remove', function(name, value)
    local player = ABT.GetPlayerData(PlayerPedId())
    local character = player.getCurrentCharacter()

    character.needs.removeNeed(name, value)
end)

RegisterNetEvent('ambitions:command:revivePlayer', function()
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    local playerHeading = GetEntityHeading(player)

    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait()
    end

    SetEntityCoordsNoOffset(player, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
    NetworkResurrectLocalPlayer(playerCoords.x, playerCoords.y, playerCoords.z, playerHeading, true, false)
    SetPlayerInvincible(player, false)
    ClearPedBloodDamage(player)
    ClearTimecycleModifier()
    SetPedMotionBlur(player, false)
    ClearExtraTimecycleModifier()
    DoScreenFadeIn(1000)
end)