CreateThread(function()
    while true do
        Wait(1000)

        local playerPed = PlayerPedId()
        local health = (GetEntityHealth(playerPed) - 100) / (GetEntityMaxHealth(playerPed) - 100) * 100
        local shield = GetPedArmour(playerPed)

        TriggerServerEvent('ambitions:server:requestPlayerNeeds')

        SendNUIMessage({
            action = 'updateStatus',
            health = health,
            shield = shield
        })
    end
end)

RegisterNetEvent('ambitions:client:updatePlayerNeeds', function(hunger, thirst)
    SendNUIMessage({
        action = 'updateStatus',
        hunger = hunger,
        thirst = thirst
    })
end)
