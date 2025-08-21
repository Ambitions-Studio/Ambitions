local spawnConfig = require('Ambitions.config.multicharacter')

--- Modern Character Object Class to handle the character data
---@param sessionId number The session id of the player
---@param uniqueId string The unique identifier for this character
---@param data table All character data
---@return AmbitionsCharacterObject characterObject The character object instance
local function CreateAmbitionsCharacterObject(sessionId, uniqueId, data)

  ---@class AmbitionsCharacterObject
  ---@field sessionId number The session id of the player
  ---@field uniqueId string The unique identifier for this character
  ---@field pedModel string The model of the character
  ---@field position table Current position {x, y, z, heading}
  ---@field group string Character's permission group
  ---@field isActive boolean Whether this character is currently active
  ---@field lastPlayed number Timestamp of last play session
  ---@field createdAt number Character creation timestamp
  ---@field playtime number Character playtime in seconds
  local self = {}
  self.sessionId = sessionId
  self.uniqueId = uniqueId
  self.pedModel = data.pedModel or spawnConfig.defaultModel
  self.position = data.position or {x = 0, y = 0, z = 70, heading = 0}
  self.group = data.group or "user"
  self.isActive = false
  self.lastPlayed = data.lastPlayed or os.time()
  self.createdAt = data.createdAt or os.time()
  self.playtime = data.playtime or 0

  --- Trigger an event for the user
  ---@param eventName string The name of the event to trigger
  ---@param ... any Additional arguments to pass to the event
  function self:triggerEvent(eventName, ...)
    assert(type(eventName) == 'string', 'eventName must be a string')

    TriggerClientEvent(eventName, self.sessionId, self, ...)
  end

  --- Get user source / session ID
  ---@return number sessionId The user's session ID
  function self:getSessionId()
    return self.sessionId
  end

  --- Get character's unique ID
  ---@return string uniqueId The character's unique ID
  function self:getUniqueId()
    return self.uniqueId
  end

  --- Get character's current position
  ---@param isVector boolean Whether to return coords formatted as a vector or not
  ---@param hasHeading boolean Is heading needed or not
  ---@return vector4 | vector3 | table position Return coords as a vector or table
  function self:getPosition(isVector, hasHeading)
    local player <const> = GetPlayerPed(self:getSessionId())
    local playerPosition <const> = GetEntityCoords(player)
    local playerHeading <const> = GetEntityHeading(player)
    local coords = { x = playerPosition.x, y = playerPosition.y, z = playerPosition.z }

    if isVector then
      coords = ( hasHeading and vector4(playerPosition.x, playerPosition.y, playerPosition.z, playerHeading) or playerPosition)
    else
      if hasHeading then
        coords.heading = playerHeading
      end
    end

    return coords
  end

  --- Check if character is active
  ---@return boolean active Whether the character is active
  function self:isCharacterActive()
    return self.isActive
  end

  --- Get character's ped model
  ---@return string pedModel The character's ped model
  function self:getPedModel()
    return self.pedModel
  end

  --- Get character's group
  ---@return string group The character's permission group
  function self:getGroup()
    return self.group
  end

  --- Get character's last played timestamp
  ---@return number lastPlayed Timestamp of last play session
  function self:getLastPlayed()
    return self.lastPlayed
  end

  --- Get character's creation timestamp
  ---@return number createdAt Character creation timestamp
  function self:getCreatedAt()
    return self.createdAt
  end

  --- Get character's playtime with real-time update using native
  ---@return number playtime Character playtime in seconds
  function self:getPlaytime()
    if self.isActive then
      local sessionTime = GetPlayerTimeOnline(self.sessionId) / 1000
      return self.playtime + sessionTime
    end

    return self.playtime
  end

  --- Set character's position
  ---@param position vector4 | vector3 | table The position to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self:setPosition(position)
    local player <const> = GetPlayerPed(self:getSessionId())

    SetEntityCoords(player, position.x, position.y, position.z, false, false, false, false)
    SetEntityHeading(player, position.w or position.heading or 0.0)

    self.position = position

    return self
  end

  --- Set character as active/inactive
  ---@param status boolean Active status
  ---@return AmbitionsCharacterObject self For method chaining
  function self:setActive(status)
    if not status and self.isActive then
      self:updatePlaytime()
    end
    
    self.isActive = status
    if status then
      self:updateLastPlayed()
    end

    return self
  end

  --- Set character's ped model
  ---@param model string The model to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self:setPedModel(model)
    self.pedModel = model

    return self
  end

  --- Set character's group
  ---@param group string The group to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self:setGroup(group)
    self.group = group

    return self
  end

  --- Update last played timestamp
  ---@return AmbitionsCharacterObject self For method chaining
  function self:updateLastPlayed()
    self.lastPlayed = os.time()

    return self
  end

  --- Update playtime with current session time
  ---@return AmbitionsCharacterObject self For method chaining
  function self:updatePlaytime()
    if self.isActive then
      local sessionTime = GetPlayerTimeOnline(self.sessionId) / 1000
      self.playtime = self.playtime + sessionTime
    end

    return self
  end

  --- Save character data to database
  ---@return boolean success Whether the save was successful
  function self:save()
    if self.isActive then
      self:updatePlaytime()
    end
    
    -- TODO: Implement database save logic
    self:updateLastPlayed()

    return true
  end

  return self
end

return CreateAmbitionsCharacterObject