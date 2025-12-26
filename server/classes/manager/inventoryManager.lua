--- Creates a new inventory manager instance for a character
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

    --- Gets the inventory ID
    ---@return number|nil inventoryId The inventory ID
    function self.getInventoryId()
        return self.inventoryId
    end

    --- Gets all items in the inventory
    ---@return table items The items table
    function self.getItems()
        return self.items
    end

    --- Gets the maximum number of slots
    ---@return number maxSlots The maximum slots
    function self.getMaxSlots()
        return self.maxSlots
    end

    --- Gets the maximum weight capacity
    ---@return number maxWeight The maximum weight
    function self.getMaxWeight()
        return self.maxWeight
    end

    --- Sets the maximum weight capacity
    ---@param weight number The new max weight in grams
    function self.setMaxWeight(weight)
        self.maxWeight = weight
    end

    --- Sets the maximum number of slots
    ---@param slots number The new max slots
    function self.setMaxSlots(slots)
        self.maxSlots = slots
    end

    --- Checks if the player can carry a specific item
    ---@param sessionId number The player's session ID
    ---@param itemName string The name of the item
    ---@param count? number The quantity to check (defaults to 1)
    ---@return boolean success Whether the player can carry the item
    ---@return string? reason Error message if cannot carry
    function self.canCarryItem(sessionId, itemName, count)
        return exports['Ambitions-Inventory']:CanCarryItem(sessionId, itemName, count)
    end

    --- Adds an item to the inventory
    ---@param sessionId number The player's session ID
    ---@param itemName string The name of the item
    ---@param count? number The quantity to add (defaults to 1)
    ---@param slot? number Specific slot to add item to
    ---@param metadata? table Item metadata
    ---@return boolean success Whether the item was added
    ---@return number|table|string|nil slotsOrReason Slot(s) used or error message
    ---@return table? changes List of inventory changes applied
    function self.addItem(sessionId, itemName, count, slot, metadata)
        return exports['Ambitions-Inventory']:AddItem(sessionId, itemName, count, slot, metadata)
    end

    --- Checks if the player has a specific item
    ---@param sessionId number The player's session ID
    ---@param itemName string The name of the item
    ---@return boolean hasItem Whether the player has the item
    ---@return table? occurrences List of slots containing the item
    function self.hasItem(sessionId, itemName)
        return exports['Ambitions-Inventory']:HasItem(sessionId, itemName)
    end

    --- Removes an item from the inventory
    ---@param sessionId number The player's session ID
    ---@param itemName string The name of the item
    ---@param count? number The quantity to remove
    ---@param slot? number Specific slot to remove from
    ---@param metadata? table Match items with specific metadata
    ---@return boolean success Whether the item was removed
    ---@return number|string countOrReason Amount removed or error message
    ---@return table? slotsAffected List of affected slots
    ---@return table? changes List of inventory changes applied
    function self.removeItem(sessionId, itemName, count, slot, metadata)
        return exports['Ambitions-Inventory']:RemoveItem(sessionId, itemName, count, slot, metadata)
    end

    --- Returns all item definitions
    ---@return table items All item definitions indexed by name
    function self.getItemList()
        return exports['Ambitions-Inventory']:GetItemList()
    end

    --- Gets the display label for an item
    ---@param itemName string The name of the item
    ---@return string? label The item's display label or nil
    function self.getItemLabel(itemName)
        return exports['Ambitions-Inventory']:GetItemLabel(itemName)
    end

    return self
end
