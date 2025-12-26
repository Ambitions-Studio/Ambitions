RegisterNetEvent('ambitions:server:updateNeeds', function(sessionId, needsType, amount)
    local player = amb.cache.getPlayer(sessionId)
    if not player then
        return amb.print.error('Failed to update needs: Player not found for session ' .. tostring(sessionId))
    end

    local character = player.getCurrentCharacter()
    if not character then
        return amb.print.error('Failed to update needs: No active character for session ' .. tostring(sessionId))
    end

    local needsManager = character.getNeedsManager()
    if not needsManager then
        return amb.print.error('Failed to update needs: Needs manager not found for session ' .. tostring(sessionId))
    end

    needsManager.update(needsType, amount)
    local newValue = needsManager.get(needsType)
    TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, needsType, newValue)
end)