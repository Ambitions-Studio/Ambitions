CreateThread(function()
    amb.print.info('Waiting for Ambitions-Inventory to start...')

    while GetResourceState('Ambitions-Inventory') ~= 'started' do
        Wait(100)
    end

    amb.print.info('Ambitions-Inventory started, registering usable items...')

    --[[ ═══════════════════════════════════════════════════════════════════════
                                        FOOD
    ═══════════════════════════════════════════════════════════════════════ ]]
    local success, error = exports['Ambitions-Inventory']:CreateUsableItem('bread', function(sessionId, item)
        local player = amb.cache.getPlayer(sessionId)
        if not player then
            return amb.print.error('Failed to use bread: Player not found for session ' .. tostring(sessionId))
        end

        local character = player.getCurrentCharacter()
        if not character then
            return amb.print.error('Failed to use bread: No active character for session ' .. tostring(sessionId))
        end

        local inventoryManager = character.getInventoryManager()
        local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
        if not success then
            return amb.print.error('Failed to use bread: Could not remove item from inventory for session ' .. tostring(sessionId))
        end

        TriggerClientEvent('ambitions:client:consumeFood', sessionId)

        local needsManager = character.getNeedsManager()
        needsManager.update('hunger', 20)
        TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'hunger', needsManager.get('hunger'))
    end)

    amb.print.debug(('Register bread as a usable item %s (%s)'):format(success, error or 'ok'))

    exports['Ambitions-Inventory']:CreateUsableItem('burger', function(sessionId, item)
        local player = amb.cache.getPlayer(sessionId)
        if not player then
            return amb.print.error('Failed to use burger: Player not found for session ' .. tostring(sessionId))
        end

        local character = player.getCurrentCharacter()
        if not character then
            return amb.print.error('Failed to use burger: No active character for session ' .. tostring(sessionId))
        end

        local inventoryManager = character.getInventoryManager()
        local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
        if not success then
            return amb.print.error('Failed to use burger: Could not remove item from inventory for session ' .. tostring(sessionId))
        end

        TriggerClientEvent('ambitions:client:consumeFood', sessionId)

        local needsManager = character.getNeedsManager()
        needsManager.update('hunger', 30)
        TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'hunger', needsManager.get('hunger'))
    end)

    exports['Ambitions-Inventory']:CreateUsableItem('chocolate', function(sessionId, item)
        local player = amb.cache.getPlayer(sessionId)
        if not player then
            return amb.print.error('Failed to use chocolate: Player not found for session ' .. tostring(sessionId))
        end

        local character = player.getCurrentCharacter()
        if not character then
            return amb.print.error('Failed to use chocolate: No active character for session ' .. tostring(sessionId))
        end

        local inventoryManager = character.getInventoryManager()
        local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
        if not success then
            return amb.print.error('Failed to use chocolate: Could not remove item from inventory for session ' .. tostring(sessionId))
        end

        TriggerClientEvent('ambitions:client:consumeFood', sessionId)

        local needsManager = character.getNeedsManager()
        needsManager.update('hunger', 10)
        TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'hunger', needsManager.get('hunger'))
    end)

    --[[ ═══════════════════════════════════════════════════════════════════════
                                       DRINKS
    ═══════════════════════════════════════════════════════════════════════ ]]
    exports['Ambitions-Inventory']:CreateUsableItem('water', function(sessionId, item)
        local player = amb.cache.getPlayer(sessionId)
        if not player then
            return amb.print.error('Failed to use water: Player not found for session ' .. tostring(sessionId))
        end

        local character = player.getCurrentCharacter()
        if not character then
            return amb.print.error('Failed to use water: No active character for session ' .. tostring(sessionId))
        end

        local inventoryManager = character.getInventoryManager()
        local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
        if not success then
            return amb.print.error('Failed to use water: Could not remove item from inventory for session ' .. tostring(sessionId))
        end

        TriggerClientEvent('ambitions:client:consumeDrink', sessionId)

        local needsManager = character.getNeedsManager()
        needsManager.update('thirst', 30)
        TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'thirst', needsManager.get('thirst'))
    end)

    exports['Ambitions-Inventory']:CreateUsableItem('cola', function(sessionId, item)
        local player = amb.cache.getPlayer(sessionId)
        if not player then
            return amb.print.error('Failed to use cola: Player not found for session ' .. tostring(sessionId))
        end

        local character = player.getCurrentCharacter()
        if not character then
            return amb.print.error('Failed to use cola: No active character for session ' .. tostring(sessionId))
        end

        local inventoryManager = character.getInventoryManager()
        local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
        if not success then
            return amb.print.error('Failed to use cola: Could not remove item from inventory for session ' .. tostring(sessionId))
        end

        TriggerClientEvent('ambitions:client:consumeDrink', sessionId)

        local needsManager = character.getNeedsManager()
        needsManager.update('thirst', 15)
        TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'thirst', needsManager.get('thirst'))
    end)

    exports['Ambitions-Inventory']:CreateUsableItem('orange_juice', function(sessionId, item)
        local player = amb.cache.getPlayer(sessionId)
        if not player then
            return amb.print.error('Failed to use orange_juice: Player not found for session ' .. tostring(sessionId))
        end

        local character = player.getCurrentCharacter()
        if not character then
            return amb.print.error('Failed to use orange_juice: No active character for session ' .. tostring(sessionId))
        end

        local inventoryManager = character.getInventoryManager()
        local success = inventoryManager.removeItem(sessionId, item.name, 1, item.slot)
        if not success then
            return amb.print.error('Failed to use orange_juice: Could not remove item from inventory for session ' .. tostring(sessionId))
        end

        TriggerClientEvent('ambitions:client:consumeDrink', sessionId)

        local needsManager = character.getNeedsManager()
        needsManager.update('thirst', 25)
        TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'thirst', needsManager.get('thirst'))
    end)

    amb.print.info('All usable items registered successfully!')
end)