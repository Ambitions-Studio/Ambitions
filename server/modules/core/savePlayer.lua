--- Save user data to database
---@param license string The player's license
---@param userObject AmbitionsUserObject The user object
---@return boolean success Whether the save was successful
local function SaveUserData(license, userObject)
  if not license or not userObject then
    amb.print.error('Invalid parameters for SaveUserData')
    return false
  end

  local totalPlaytime = userObject.getTotalPlaytime()
  local lastPlayedCharacter = userObject.getLastPlayedCharacter()

  local success = MySQL.update.await(
    'UPDATE users SET last_seen = NOW(), total_playtime = ?, last_played_character = ? WHERE license = ?',
    { totalPlaytime, lastPlayedCharacter, license }
  )

  if success > 0 then
    return true
  else
    amb.print.error('Failed to save user data for license: ', license)

    return false
  end
end

--- Save character data to database
---@param characterObject AmbitionsCharacterObject The character object
---@return boolean success Whether the save was successful
local function SaveCharacterData(characterObject)
  if not characterObject then
    amb.print.error('Invalid character object for SaveCharacterData')

    return false
  end

  -- Extract all character data from cache
  local uniqueId = characterObject.getUniqueId()
  local firstname = characterObject.getFirstname()
  local lastname = characterObject.getLastname()
  local dateofbirth = characterObject.getDateOfBirth()
  local sex = characterObject.getSex()
  local nationality = characterObject.getNationality()
  local height = characterObject.getHeight()
  local appearance = characterObject.getAppearance()
  local group = characterObject.getGroup()
  local pedModel = characterObject.getPedModel()
  local playtime = characterObject.getPlaytime()
  local needs = characterObject.getNeedsManager().serialize()

  local storedPosition = characterObject.position

  local roundedX = amb.math.round(storedPosition.x, 4)
  local roundedY = amb.math.round(storedPosition.y, 4)
  local roundedZ = amb.math.round(storedPosition.z, 4)
  local roundedHeading = amb.math.round(storedPosition.heading, 4)
  local roundedPlaytime = amb.math.round(playtime)

  -- Update ALL character fields in database
  local success = MySQL.update.await([[
    UPDATE characters SET
      firstname = ?,
      lastname = ?,
      dateofbirth = ?,
      sex = ?,
      nationality = ?,
      height = ?,
      appearance = ?,
      `group` = ?,
      ped_model = ?,
      position_x = ?,
      position_y = ?,
      position_z = ?,
      heading = ?,
      needs = ?,
      playtime = ?,
      last_played = NOW()
    WHERE unique_id = ?
  ]], {
    firstname,
    lastname,
    dateofbirth,
    sex,
    nationality,
    height,
    appearance,
    group,
    pedModel,
    roundedX,
    roundedY,
    roundedZ,
    roundedHeading,
    needs,
    roundedPlaytime,
    uniqueId
  })

  if success > 0 then
    return true
  else
    amb.print.error('Failed to save character data for ID: ', uniqueId)

    return false
  end
end

--- Update cache with live data before saving
---@param sessionId number The session ID of the player
---@param playerObject AmbitionsUserObject The player object
---@return boolean success Whether the cache update was successful
local function UpdateCacheBeforeSave(sessionId, playerObject)
  local CHARACTER_OBJECT = playerObject.getCurrentCharacter()

  if not CHARACTER_OBJECT then
    amb.print.error('No character object to update cache for player: ', sessionId)

    return false
  end

  -- Update live position
  local ped = GetPlayerPed(sessionId)
  if ped and ped > 0 then
    local pedPositions = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)

    CHARACTER_OBJECT.position = {
      x = pedPositions.x,
      y = pedPositions.y,
      z = pedPositions.z,
      heading = pedHeading
    }
  else
    amb.print.warning('Could not get live position for player: ', sessionId, ' - using stored position')
  end

  -- Update playtime
  CHARACTER_OBJECT.updatePlaytime()

  -- Update last seen
  playerObject.updateLastSeen()

  -- Update last played character
  local currentCharacterUniqueId = CHARACTER_OBJECT.getUniqueId()
  if currentCharacterUniqueId then
    playerObject.lastPlayedCharacter = currentCharacterUniqueId
  end

  return true
end

--- Save a player when they drop from the server
---@param sessionId number The session ID of the player
---@param playerObject AmbitionsUserObject The player object to save
local function SavePlayerDropped(sessionId, playerObject)
  local CHARACTER_OBJECT <const> = playerObject.getCurrentCharacter()
  local PLAYER_LICENSE <const> = playerObject.getIdentifier('license')

  if not CHARACTER_OBJECT then
    amb.print.error('Player ', GetPlayerName(sessionId), ' did not have a character object and therefore could not be saved.')

    return
  end

  if not PLAYER_LICENSE then
    amb.print.error('Player ', GetPlayerName(sessionId), ' did not have a license and therefore could not be saved.')

    return
  end

  local cacheUpdated = UpdateCacheBeforeSave(sessionId, playerObject)

  if not cacheUpdated then
    amb.print.warning('Cache update failed for player: ', sessionId, ' - proceeding with stored data')
  end

  local userSaved = SaveUserData(PLAYER_LICENSE, playerObject)
  local characterSaved = SaveCharacterData(CHARACTER_OBJECT)

  if not (userSaved and characterSaved) then
    amb.print.error('Failed to save player ', GetPlayerName(sessionId))
  end

  amb.cache.removePlayer(sessionId)
end

AddEventHandler('playerDropped', function(droppedReason, resourceName, doppedClientId)
  local SESSION_ID <const> = source
  local playerObject <const> = amb.cache.getPlayer(SESSION_ID)
  if not playerObject then
    amb.print.error('Player ', GetPlayerName(SESSION_ID), ' was not found in the player cache and therefore could not be saved.')
    return
  end

  SavePlayerDropped(SESSION_ID, playerObject)
end)