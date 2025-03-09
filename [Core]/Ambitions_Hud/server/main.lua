RegisterServerEvent('ambitions:server:requestPlayerNeeds', function()
    local source = source
    local amberPlayer = ABT.GetPlayerFromId(source)

    if not amberPlayer then return end

    local character = amberPlayer.getCurrentCharacter()
    local needs = character.needs
    local hunger = needs.getNeed('hunger')
    local thirst = needs.getNeed('thirst')

    TriggerClientEvent('ambitions:client:updatePlayerNeeds', src, hunger, thirst)
end)