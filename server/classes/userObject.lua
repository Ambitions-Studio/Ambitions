local ambitionsPrint = require('shared.lib.log.print')

--- Modern User Object Class to handle the user data
---@param sessionId number The session id of the player
---@param playerLicense string The license of the player
---@return AmbitionsUserObject userObject The user object instance
local function CreateAmbitionsUserObject(sessionId, playerLicense)

  ---@class AmbitionsUserObject
  ---@field sessionId number The player's server ID
  ---@field license string The player's license
  ---@field identifiers table All player's identifiers
  ---@field characters table A table of the player's characters indexed by uniqueID
  ---@field currentCharacter AmbitionsCharacterObject | nil The currently active character
  ---@field isOnline boolean Whether the user is currently online
  ---@field lastSeen number Timestamp of last activity
  ---@field lastPlayedCharacter string | nil The unique ID of the last played character
  ---@field totalPlaytime number Total playtime across all characters in seconds
  local self = {}
  self.sessionId = sessionId
  self.license = playerLicense
  self.identifiers = {}
  self.characters = {}
  self.currentCharacter = nil
  self.isOnline = true
  self.lastSeen = os.time()
  self.lastPlayedCharacter = nil
  self.totalPlaytime = 0

  --- Get user license
  ---@return string license The user's license
  function self:getLicense()
    return self.license
  end

  --- Get user source / session ID
  ---@return number sessionId The user's session ID
  function self:getSessionId()
    return self.sessionId
  end

  --- Get all identifiers
  ---@return table identifiers All identifiers for this user
  function self:getAllIdentifiers()
    return self.identifiers
  end

  --- Get a specific identifier
  ---@param identifierType string Type of identifier (steam, discord, etc.)
  ---@return string | nil identifier The identifier value or nil if not found
  function self:getIdentifier(identifierType)
    return self.identifiers[identifierType]
  end

  --- Get the currently active character
  ---@return AmbitionsCharacterObject | nil character The currently active character or nil
  function self:getCurrentCharacter()
    return self.currentCharacter
  end

  --- Get a specific character by unique ID
  ---@param uniqueId string The unique ID of the character
  ---@return AmbitionsCharacterObject | nil character The character or nil if not found
  function self:getCharacter(uniqueId)
    return self.characters[uniqueId]
  end

  --- Get all characters belonging to the user
  ---@return table characters A table of all characters indexed by uniqueId
  function self:getAllCharacters()
    return self.characters
  end

  --- Get count of characters
  ---@return number count Number of characters this user has
  function self:getCharacterCount()
    local count = 0

    for _ in pairs(self.characters) do
      count = count + 1
    end

    return count
  end

  --- Check if user is online
  ---@return boolean online Whether the user is online
  function self:isUserOnline()
    return self.isOnline
  end

  --- Get last seen timestamp
  ---@return number lastSeen Timestamp of last activity
  function self:getLastSeen()
    return self.lastSeen
  end

  --- Get last played character unique ID
  ---@return string | nil lastPlayedCharacter The unique ID of the last played character
  function self:getLastPlayedCharacter()
    return self.lastPlayedCharacter
  end

  --- Get total playtime across all characters
  ---@return number totalPlaytime Total playtime in seconds calculated from all characters
  function self:getTotalPlaytime()
    local total = 0
    for _, character in pairs(self.characters) do
      if character.getPlaytime then
        total = total + character:getPlaytime()
      end
    end

    self.totalPlaytime = total

    return total
  end

  --- Set all identifiers for this user
  ---@param identifiers table Table of identifiers from identifiers module
  ---@return AmbitionsUserObject self For method chaining
  function self:setIdentifiers(identifiers)
    self.identifiers = identifiers or {}

    return self
  end

  --- Set the active character for the user
  ---@param uniqueId string The unique ID of the character to set as active
  ---@return boolean success Whether the operation was successful
  function self:setCurrentCharacter(uniqueId)
    if not uniqueId or not self.characters[uniqueId] then
      return false
    end

    self.currentCharacter = self.characters[uniqueId]
    self.lastPlayedCharacter = uniqueId

    return true
  end

  --- Set online status
  ---@param status boolean The online status
  ---@return AmbitionsUserObject self For method chaining
  function self:setOnlineStatus(status)
    self.isOnline = status

    if not status then
      self:updateLastSeen()
    end

    return self
  end

  --- Add a character to the user's character list
  ---@param characterObject AmbitionsCharacterObject The character to add
  ---@return boolean success Whether the character was added successfully
  function self:addCharacter(characterObject)
    if not characterObject or not characterObject.getUniqueId then
      ambitionsPrint.error("Invalid character object provided to addCharacter")
      return false
    end

    local uniqueId = characterObject:getUniqueId()

    if self.characters[uniqueId] then
      ambitionsPrint.error("Character with ID " .. uniqueId .. " already exists")
      return false
    end

    self.characters[uniqueId] = characterObject

    return true
  end

  --- Remove a character from the user's character list
  ---@param uniqueId string The unique ID of the character to remove
  ---@return boolean success Whether the removal was successful
  function self:removeCharacter(uniqueId)
    if not uniqueId or not self.characters[uniqueId] then
      return false
    end

    -- Clear current character if it's the one being removed
    if self.currentCharacter and self.currentCharacter:getUniqueId() == uniqueId then
      self.currentCharacter = nil
    end

    self.characters[uniqueId] = nil

    return true
  end

  --- Update last seen timestamp
  ---@return AmbitionsUserObject self For method chaining
  function self:updateLastSeen()
    self.lastSeen = os.time()

    return self
  end

  --- Disconnect the user from the server
  ---@param reason string|nil The reason for disconnection
  ---@return AmbitionsUserObject self For method chaining
  function self:drop(reason)
    reason = reason or "Disconnected by server"
    if self.isOnline then
      DropPlayer(self.sessionId, reason)
      self.isOnline = false
    end

    return self
  end

  return self
end

return CreateAmbitionsUserObject