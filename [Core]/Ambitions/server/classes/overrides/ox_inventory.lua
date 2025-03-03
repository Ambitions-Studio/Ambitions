local inventoryConfig = import('config.shared.config_inventory')
local Inventory

if inventoryConfig.INVENTORY ~= 'ox' then return end

AddEventHandler('ox_inventory:loadInventory', function(module)
    Inventory = module
end)

ABT.PlayerFunctionOverrides.OxInventory = {
    getInventory = function(self)
        return function(minimal)
            if not minimal then
                return self.inventory
            end
        end
    end,
}