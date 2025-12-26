RegisterNetEvent('ambitions:server:swapSlots', function(fromSlot, toSlot)
    local sessionId = source
    if not sessionId or not fromSlot or not toSlot then
        return
    end

    local player = amb.cache.getPlayer(sessionId)
    if not player then
        return
    end

    local character = player.getCurrentCharacter()
    if not character then
        return
    end

    local inventoryManager = character.getInventoryManager()
    if not inventoryManager then
        return
    end

    local items = inventoryManager.getItems()

    local temp = items[fromSlot]
    items[fromSlot] = items[toSlot]
    items[toSlot] = temp
end)

RegisterNetEvent('ambitions:server:mergeItems', function(fromSlot, toSlot)
    local sessionId = source
    if not sessionId or not fromSlot or not toSlot then
        return
    end

    local player = amb.cache.getPlayer(sessionId)
    if not player then
        return
    end

    local character = player.getCurrentCharacter()
    if not character then
        return
    end

    local inventoryManager = character.getInventoryManager()
    if not inventoryManager then
        return
    end

    local items = inventoryManager.getItems()

    local fromItem = items[fromSlot]
    local toItem = items[toSlot]

    if fromItem and toItem and fromItem.name == toItem.name then
        toItem.count = toItem.count + fromItem.count
        items[fromSlot] = nil
    end
end)

AddEventHandler('ambitions:server:applyChanges', function(sessionId, changes)
    if not sessionId or not changes then
        return
    end

    local player = amb.cache.getPlayer(sessionId)
    if not player then
        return
    end

    local character = player.getCurrentCharacter()
    if not character then
        return
    end

    local inventoryManager = character.getInventoryManager()
    if not inventoryManager then
        return
    end

    local items = inventoryManager.getItems()

    for _, change in ipairs(changes) do
        if change.action == 'set' then
            items[change.slot] = change.data
            TriggerClientEvent('ambitions-inventory:client:addItem', sessionId, change.slot, change.data)
        elseif change.action == 'update' then
            items[change.slot] = change.data
            TriggerClientEvent('ambitions-inventory:client:updateItem', sessionId, change.slot, change.data)
        elseif change.action == 'remove' then
            items[change.slot] = nil
            TriggerClientEvent('ambitions-inventory:client:removeItem', sessionId, change.slot)
        end
    end
end)
