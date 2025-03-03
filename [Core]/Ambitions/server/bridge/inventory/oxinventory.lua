local inventoryConfig = import('config.shared.config_inventory')
local startingAccount = import('config.shared.config_spawn')

if inventoryConfig.INVENTORY ~= 'ox' then return end

MySQL.ready(function()
    TriggerEvent("__cfx_export_ox_inventory_Items", function(ref)
        if ref then
            ABT.Items = ref()
        end
    end)

    AddEventHandler('ox_inventory:itemList', function(items)
        ABT.Items = items
    end)
end)

ABT.Item.GetItemLabel = function(item)
    item = exports.ox_inventory:Items(item)
    if item then
        return item.label
    end
end

function setPlayerInventory(playerId, amberPlayer, inventory, isNew)
    exports.ox_inventory:setPlayerInventory(amberPlayer, inventory)

    if isNew then
        local shared = json.decode(GetConvar('inventory:accounts', '["cash"]'))

        for i = 1, #shared do
            local name = shared[i]
            local account = startingAccount.STARTING_ACCOUNT_MONEY[name]

            if account then
                exports.ox_inventory:AddItem(playerId, name, account)
            end
        end
    end
end