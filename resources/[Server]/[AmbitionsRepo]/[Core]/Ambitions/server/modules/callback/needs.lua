ABT.Callback.Register('ambitions:server:getNeed', function(source, need)
    local player = ABT.GetPlayerFromId(source)
    if not player then
        ABT.Print.Log(3, 'Failed to retrieve player in getNeed callback')
        return nil
    end

    local character = player.getCurrentCharacter()
    if not character then
        ABT.Print.Log(3, 'Failed to retrieve character in getNeed callback')
        return nil
    end

    ABT.Print.Log(5, character.needs.getNeed(need))
    return character.needs.getNeed(need)
end)

ABT.Callback.Register('ambitions:server:removeNeed', function(source, need, amount)
    local player = ABT.GetPlayerFromId(source)
    if not player then
        ABT.Print.Log(3, 'Failed to retrieve player in removeNeed callback')
        return false
    end

    local character = player.getCurrentCharacter()
    if not character then
        ABT.Print.Log(3, 'Failed to retrieve character in removeNeed callback')
        return false
    end

    local currentNeed = character.needs.getNeed(need)
    if not currentNeed then
        ABT.Print.Log(3, ('Need %s does not exist for character.'):format(need))
        return false
    end

    if currentNeed > 0 then
        local newValue = math.max(0, currentNeed - amount)
        character.needs.setNeed(need, newValue)
        ABT.Print.Log(2, ('%s reduced to %s'):format(need, newValue))
        return true
    else
        ABT.Print.Log(3, ('Need %s is already at minimum value. Modification skipped.'):format(need))
        return false
    end
end)