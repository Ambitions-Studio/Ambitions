
---@param characterId string The character unique ID
---@param inventoryId number|nil The inventory ID from database
---@return AmbitionsInventoryManager inventoryManager The inventory manager instance
function CreateAmbitionsInventoryManager(characterId, inventoryId)

    ---@class AmbitionsInventoryManager
    ---@field characterId string The character unique ID
    ---@field inventoryId number|nil The inventory ID
    ---@field items table Items in inventory (cached)
    ---@field maxSlots number Maximum slots
    ---@field maxWeight number Maximum weight
    local self = {}

    self.characterId = characterId
    self.inventoryId = inventoryId
    self.items = {}
    self.maxSlots = exports['Ambitions-Inventory']:GetDefaultMaxSlots()
    self.maxWeight = exports['Ambitions-Inventory']:GetDefaultMaxWeight()

    function self.getInventoryId()
        return self.inventoryId
    end

    function self.getItems()
        return self.items
    end

    function self.getMaxSlots()
        return self.maxSlots
    end

    function self.getMaxWeight()
        return self.maxWeight
    end

    ---@param weight number The new max weight in grams
    function self.setMaxWeight(weight)
        self.maxWeight = weight
    end

    ---@param slots number The new max slots
    function self.setMaxSlots(slots)
        self.maxSlots = slots
    end

    function self.addItem(sessionId, itemName, count, slot, metadata)
        return exports['Ambitions-Inventory']:AddItem(sessionId, itemName, count, slot, metadata)
    end

    function self.hasItem(sessionId, itemName)
        return exports['Ambitions-Inventory']:HasItem(sessionId, itemName)
    end

    function self.removeItem(sessionId, itemName, count, slot, metadata)
        return exports['Ambitions-Inventory']:RemoveItem(sessionId, itemName, count, slot, metadata)
    end

    return self
end
