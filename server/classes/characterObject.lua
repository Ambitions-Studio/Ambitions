--- Modern Character Object Class to handle the character data
---@param sessionId number The session id of the player
---@param uniqueId string The unique identifier for this character
---@param data table All character data
---@return AmbitionsCharacterObject characterObject The character object instance
function CreateAmbitionsCharacterObject(sessionId, uniqueId, data)

  ---@class AmbitionsCharacterObject
  ---@field sessionId number The session id of the player
  ---@field uniqueId string The unique identifier for this character
  ---@field firstname string Character's first name
  ---@field lastname string Character's last name
  ---@field dateofbirth string Character's date of birth (DD/MM/YYYY)
  ---@field sex string Character's sex (M/F)
  ---@field nationality string Character's nationality
  ---@field height number Character's height in cm
  ---@field appearance string | nil Character's appearance data (JSON or serialized)
  ---@field pedModel string The model of the character
  ---@field position table | vector3 | vector4 Current position {x, y, z, heading}
  ---@field group string Character's permission group
  ---@field isActive boolean Whether this character is currently active
  ---@field lastPlayed number | nil Timestamp of last play session
  ---@field createdAt number | nil Character creation timestamp
  ---@field playtime number Character playtime in seconds
  local self = {}
  self.sessionId = sessionId
  self.uniqueId = uniqueId
  self.firstname = data.firstname or ""
  self.lastname = data.lastname or ""
  self.dateofbirth = data.dateofbirth or ""
  self.sex = data.sex or "M"
  self.nationality = data.nationality or ""
  self.height = data.height or 175
  self.appearance = data.appearance or nil
  self.pedModel = data.pedModel or 'mp_m_freemode_01'
  self.position = data.position or {x = 0, y = 0, z = 70, heading = 0}
  self.group = data.group or "user"
  self.isActive = false
  self.lastPlayed = data.lastPlayed or nil
  self.createdAt = data.createdAt or nil
  self.playtime = data.playtime or 0

  --- Trigger an event for the user
  ---@param eventName string The name of the event to trigger
  ---@param ... any Additional arguments to pass to the event
  function self.triggerEvent(eventName, ...)
    assert(type(eventName) == 'string', 'eventName must be a string')

    TriggerClientEvent(eventName, self.sessionId, self, ...)
  end

  --- Get user source / session ID
  ---@return number sessionId The user's session ID
  function self.getSessionId()
    return self.sessionId
  end

  --- Get character's unique ID
  ---@return string uniqueId The character's unique ID
  function self.getUniqueId()
    return self.uniqueId
  end

  --- Get character's current position
  ---@param isVector boolean Whether to return coords formatted as a vector or not
  ---@param hasHeading boolean Is heading needed or not
  ---@return vector4 | vector3 | table position Return coords as a vector or table
  function self.getPosition(isVector, hasHeading)
    local player <const> = GetPlayerPed(self.getSessionId())
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

    self.position = coords
    return coords
  end

  --- Check if character is active
  ---@return boolean active Whether the character is active
  function self.isCharacterActive()
    return self.isActive
  end

  --- Get character's ped model
  ---@return string pedModel The character's ped model
  function self.getPedModel()
    return self.pedModel
  end

  --- Get character's group
  ---@return string group The character's permission group
  function self.getGroup()
    return self.group
  end

  --- Get character's last played timestamp
  ---@return number lastPlayed Timestamp of last play session
  function self.getLastPlayed()
    return self.lastPlayed
  end

  --- Get character's creation timestamp
  ---@return number | nil createdAt Character creation timestamp
  function self.getCreatedAt()
    return self.createdAt
  end

  --- Get character's first name
  ---@return string firstname Character's first name
  function self.getFirstname()
    return self.firstname
  end

  --- Get character's last name
  ---@return string lastname Character's last name
  function self.getLastname()
    return self.lastname
  end

  --- Get character's full name
  ---@return string fullname Character's full name (firstname lastname)
  function self.getFullName()
    return self.firstname .. " " .. self.lastname
  end

  --- Get character's date of birth
  ---@return string dateofbirth Character's date of birth (DD/MM/YYYY)
  function self.getDateOfBirth()
    return self.dateofbirth
  end

  --- Get character's age calculated from date of birth
  ---@return number | nil age Character's age in years or nil if invalid date
  function self.getAge()
    if not self.dateofbirth or self.dateofbirth == "" then
      return nil
    end

    local day, month, year = self.dateofbirth:match("(%d+)/(%d+)/(%d+)")
    if not day or not month or not year then
      return nil
    end

    day, month, year = tonumber(day), tonumber(month), tonumber(year)
    if not day or not month or not year then
      return nil
    end

    local currentDate = os.date("*t")
    local age = currentDate.year - year

    if currentDate.month < month or (currentDate.month == month and currentDate.day < day) then
      age = age - 1
    end

    return age
  end

  --- Get character's sex
  ---@return string sex Character's sex (M/F)
  function self.getSex()
    return self.sex
  end

  --- Get character's nationality
  ---@return string nationality Character's nationality
  function self.getNationality()
    return self.nationality
  end

  --- Get character's height
  ---@return number height Character's height in cm
  function self.getHeight()
    return self.height
  end

  --- Get character's appearance data
  ---@return string | nil appearance Character's appearance data
  function self.getAppearance()
    return self.appearance
  end

  --- Get character's playtime with real-time update using native
  ---@return number playtime Character playtime in seconds
  function self.getPlaytime()
    if self.isActive then
      local sessionTime = GetPlayerTimeOnline(self.sessionId) / 1000
      return self.playtime + sessionTime
    end

    return self.playtime
  end

  --- Set character's position
  ---@param position vector4 | vector3 | table The position to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setPosition(position)
    local player <const> = GetPlayerPed(self.getSessionId())

    SetEntityCoords(player, position.x, position.y, position.z, false, false, false, false)
    SetEntityHeading(player, position.w or position.heading or 0.0)

    self.position = position

    return self
  end

  --- Set character as active/inactive
  ---@param status boolean Active status
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setActive(status)
    if not status and self.isActive then
      self.updatePlaytime()
    end
    
    self.isActive = status
    if status then
      self.updateLastPlayed()
    end

    return self
  end

  --- Set character's ped model
  ---@param model string The model to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setPedModel(model)
    if not model or type(model) ~= "string" or model == "" then
      amb.print.error("Invalid ped model provided to setPedModel")
      return self
    end

    self.pedModel = model

    return self
  end

  --- Set character's group
  ---@param group string The group to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setGroup(group)
    self.group = group

    return self
  end

  --- Set character's first name
  ---@param firstname string The first name to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setFirstname(firstname)
    self.firstname = firstname or ""

    return self
  end

  --- Set character's last name
  ---@param lastname string The last name to set
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setLastname(lastname)
    self.lastname = lastname or ""

    return self
  end

  --- Set character's date of birth
  ---@param dateofbirth string The date of birth (DD/MM/YYYY)
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setDateOfBirth(dateofbirth)
    self.dateofbirth = dateofbirth or ""

    return self
  end

  --- Set character's sex
  ---@param sex string The sex (M/F)
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setSex(sex)
    self.sex = sex or "M"

    return self
  end

  --- Set character's nationality
  ---@param nationality string The nationality
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setNationality(nationality)
    self.nationality = nationality or ""

    return self
  end

  --- Set character's height
  ---@param height number The height in cm
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setHeight(height)
    self.height = height or 175

    return self
  end

  --- Set character's appearance data
  ---@param appearance string | nil The appearance data
  ---@return AmbitionsCharacterObject self For method chaining
  function self.setAppearance(appearance)
    self.appearance = appearance

    return self
  end

  --- Update last played timestamp
  ---@return AmbitionsCharacterObject self For method chaining
  function self.updateLastPlayed()
    self.lastPlayed = os.time()

    return self
  end

  --- Update playtime with current session time
  ---@return AmbitionsCharacterObject self For method chaining
  function self.updatePlaytime()
    if self.isActive then
      local sessionTime = GetPlayerTimeOnline(self.sessionId) / 1000
      self.playtime = self.playtime + sessionTime
    end

    return self
  end

  --- Save character data to database
  ---@return boolean success Whether the save was successful
  function self.save()
    if self.isActive then
      self.updatePlaytime()
    end
    
    -- TODO: Implement database save logic
    self.updateLastPlayed()

    return true
  end

  return self
end