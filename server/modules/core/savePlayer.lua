local ambitionsPrint = require('shared.lib.log.print')

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

  ambitionsPrint.debug('Saving player ', GetPlayerName(sessionId), ' with license ', PLAYER_LICENSE, ' and user object ', playerObject, ' and character object ', CHARACTER_OBJECT, '.')
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