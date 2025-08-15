local ambitionsPrint = require('shared.lib.log.print')
local playerCache = require('server.lib.cache.player')

--- Save user data to database
---@param license string The player's license
---@param userObject AmbitionsUserObject The user object
---@return boolean success Whether the save was successful
local function SaveUserData(license, userObject)
  if not license or not userObject then
    ambitionsPrint.error('Invalid parameters for SaveUserData')
    return false
  end

  local totalPlaytime = userObject:getTotalPlaytime()
  local lastPlayedCharacter = userObject:getLastPlayedCharacter()

  local success = MySQL.update.await(
    'UPDATE users SET last_seen = NOW(), total_playtime = ?, last_played_character = ? WHERE license = ?',
    { totalPlaytime, lastPlayedCharacter, license }
  )

  if success > 0 then
    ambitionsPrint.debug('User data saved for license: ', license)
    return true
  else
    ambitionsPrint.error('Failed to save user data for license: ', license)
    return false
  end
end

--- Save character data to database
---@param characterObject AmbitionsCharacterObject The character object
---@return boolean success Whether the save was successful
local function SaveCharacterData(characterObject)
  if not characterObject then
    ambitionsPrint.error('Invalid character object for SaveCharacterData')
    return false
  end

  local currentPosition = characterObject:getPosition(false, true)
  local playtime = characterObject:getPlaytime()
  local pedModel = characterObject:getPedModel()
  local uniqueId = characterObject:getUniqueId()

  local success = MySQL.update.await(
    'UPDATE characters SET ped_model = ?, position_x = ?, position_y = ?, position_z = ?, heading = ?, playtime = ?, last_played = NOW() WHERE unique_id = ?',
    { pedModel, currentPosition.x, currentPosition.y, currentPosition.z, currentPosition.heading, playtime, uniqueId }
  )

  if success > 0 then
    ambitionsPrint.debug('Character data saved for ID: ', uniqueId)
    return true
  else
    ambitionsPrint.error('Failed to save character data for ID: ', uniqueId)
    return false
  end
end

--- Save a player when they drop from the server
---@param sessionId number The session ID of the player
---@param playerObject AmbitionsUserObject The player object to save
local function SavePlayerDropped(sessionId, playerObject)
  local CHARACTER_OBJECT <const> = playerObject:getCurrentCharacter()
  local PLAYER_LICENSE <const> = playerObject:getIdentifier('license')

  if not CHARACTER_OBJECT then
    ambitionsPrint.error('Player ', GetPlayerName(sessionId), ' did not have a character object and therefore could not be saved.')
    return
  end

  if not PLAYER_LICENSE then
    ambitionsPrint.error('Player ', GetPlayerName(sessionId), ' did not have a license and therefore could not be saved.')
    return
  end

  ambitionsPrint.info('Saving player ', GetPlayerName(sessionId), ' before disconnect')

  CHARACTER_OBJECT:updatePlaytime()

  local userSaved = SaveUserData(PLAYER_LICENSE, playerObject)
  local characterSaved = SaveCharacterData(CHARACTER_OBJECT)

  if userSaved and characterSaved then
    ambitionsPrint.success('Player ', GetPlayerName(sessionId), ' saved successfully')
  else
    ambitionsPrint.error('Failed to save player ', GetPlayerName(sessionId))
  end

  playerCache.remove(sessionId)
end

AddEventHandler('playerDropped', function(droppedReason, resourceName, doppedClientId)
  local SESSION_ID <const> = source
  local playerObject <const> = playerCache.get(SESSION_ID)
  if not playerObject then
    ambitionsPrint.error('Player ', GetPlayerName(SESSION_ID), ' was not found in the player cache and therefore could not be saved.')
    return
  end

  SavePlayerDropped(SESSION_ID, playerObject)
end)