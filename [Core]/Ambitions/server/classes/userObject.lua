---@param source number The player's server ID.
---@param license string The player's license.
function CreateAmberUser(source, license)

    ---@class amberPlayer
    ---@field source number The player's server ID.
    ---@field license string The player's license.
    ---@field characters table A table of the player's characters.
    ---@field currentCharacter amberCharacter The currently active character.
    local self = {}
    self.source = source
    self.license = 'license:' .. license
    self.characters = {}
    self.currentCharacter = nil -- Reference to the active character.

    ---@param license string The player's license.
    ---@return void
    function self.setLicense(license)
        self.license = 'license:' .. license
    end

    ---@return string license The player's license.
    function self.getLicense()
        return self.license
    end

    --- Add a character to the user's character list.
    ---@param character amberCharacter The character to add.
    ---@return void
    function self.addCharacter(character)
        if not character or not character.getUniqueID then
            error("Invalid character object provided.")
        end
        self.characters[character.getUniqueID()] = character
    end

    --- Remove a character from the user's character list.
    ---@param uniqueID string The unique ID of the character to remove.
    ---@return boolean success Whether the removal was successful.
    function self.removeCharacter(uniqueID)
        if self.characters[uniqueID] then
            self.characters[uniqueID] = nil
            if self.currentCharacter and self.currentCharacter.getUniqueID() == uniqueID then
                self.currentCharacter = nil
            end
            return true
        end
        return false
    end

    --- Set the active character for the user.
    ---@param uniqueID string The unique ID of the character to set as active.
    ---@return boolean success Whether the operation was successful.
    function self.setCurrentCharacter(uniqueID)
        if self.characters[uniqueID] then
            self.currentCharacter = self.characters[uniqueID]
            return true
        end
        return false
    end

    --- Get the currently active character.
    ---@return amberCharacter|nil The currently active character or nil if none is active.
    function self.getCurrentCharacter()
        return self.currentCharacter
    end

    --- Get a character by unique ID.
    ---@param uniqueID string The unique ID of the character.
    ---@return amberCharacter|nil The character with the given unique ID or nil if not found.
    function self.getCharacter(uniqueID)
        return self.characters[uniqueID]
    end

    --- Get all characters belonging to the user.
    ---@return table characters A table of all characters.
    function self.getAllCharacters()
        return self.characters
    end

    return self
end