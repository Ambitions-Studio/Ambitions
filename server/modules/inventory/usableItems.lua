exports['Ambitions-Inventory']:CreateUsableItem('bread', function(sessionId, item)
    local player = amb.cache.getPlayer(sessionId)
    if not player then
        return
    end

    local character = player.getCurrentCharacter()
    if not character then
        return
    end

    local inventoryManager = character.getInventoryManager()
    local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
    if not success then
        return
    end

    local needsManager = character.getNeedsManager()
    needsManager.update('hunger', 15)

    local newValue = needsManager.get('hunger')
    TriggerClientEvent('ambitions:client:updateNeed', sessionId, 'hunger', newValue)
end)
