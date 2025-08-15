local ambitionsPrint = require('shared.lib.log.print')
local identifiers = require('server.lib.player.identifiers')
local random = require('shared.lib.math.random')
local spawnConfig = require('config.spawn')
local userObject = require('server.classes.userObject')
local characterObject = require('server.classes.characterObject')
local playerCache = require('server.lib.cache.player')

--- Check if the unique id is already in use by a character
---@param uniqueId string The unique id to check
---@return boolean isInUse True if the unique id is in use, false otherwise
local function isUniqueIdInUse(uniqueId)

  local count = MySQL.scalar.await('SELECT COUNT(*) FROM characters WHERE unique_id = ?', { uniqueId })

  return count > 0
end

--- Get a valid unique id for the character
---@param sessionId number The session id of the player
---@return string | nil uniqueId The unique id or nil if failed to generate a valid unique id
local function GetValidUniqueId(sessionId)
  local uniqueId
  local maxAttempts = 10
  for _ = 1, maxAttempts do
    uniqueId = random.alphanumeric(6)
    if not isUniqueIdInUse(uniqueId) then
      return uniqueId
    end
  end

  ambitionsPrint.error('Failed to generate a valid unique id for player: ', sessionId, ' after ', maxAttempts, ' attempts')
  return nil
end

--- Create a new character in the database
---@param sessionId number The session id of the player
---@param userId number The user id of the player
---@param ambitionsUser AmbitionsUserObject The user object
local function CreateCharacter(sessionId, userId, ambitionsUser)
  local characterData = {
    uniqueId = GetValidUniqueId(sessionId),
    group = 'user',
    pedModel = spawnConfig.defaultModel,
    spawnPosition = {
      x = spawnConfig.defaultSpawnPosition.x,
      y = spawnConfig.defaultSpawnPosition.y,
      z = spawnConfig.defaultSpawnPosition.z,
      heading = spawnConfig.defaultSpawnPosition.w
    }
  }

  if not characterData.uniqueId then
    ambitionsPrint.error('Failed to generate a valid unique id for player: ', sessionId)
    DropPlayer(sessionId, 'Failed to generate a valid unique id, please contact an administrator.')
    return
  end

  MySQL.insert.await('INSERT INTO characters (user_id, unique_id, `group`, ped_model, position_x, position_y, position_z, heading) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', { userId, characterData.uniqueId, characterData.group, characterData.pedModel, characterData.spawnPosition.x, characterData.spawnPosition.y, characterData.spawnPosition.z, characterData.spawnPosition.heading })

  local ambitionsCharacter = characterObject(sessionId, characterData.uniqueId, characterData)
  ambitionsUser:addCharacter(ambitionsCharacter)
  ambitionsUser:setCurrentCharacter(characterData.uniqueId)
  ambitionsUser:getCurrentCharacter():setActive(true)

  playerCache.add(sessionId, ambitionsUser)

  ambitionsPrint.debug('Player added to cache: ', sessionId)
  ambitionsPrint.debug('Player cache: ', playerCache.get(sessionId))
  ambitionsPrint.debug('All players in cache : ', playerCache.getAll())

  TriggerClientEvent('ambitions:client:playerLoaded', sessionId, characterData.pedModel, vector4(characterData.spawnPosition.x, characterData.spawnPosition.y, characterData.spawnPosition.z, characterData.spawnPosition.heading))
end

--- Create a new user in the database
---@param sessionId number The session id of the player
---@param identifiers table The identifiers of the player
local function CreateUser(sessionId, identifiers)
  local PLAYER_LICENSE <const> = identifiers.license
  local PLAYER_DISCORD_ID <const> = identifiers.discord
  local PLAYER_IP <const> = identifiers.ip

  if not PLAYER_LICENSE or not PLAYER_IP then
    ambitionsPrint.error('failed to get mandatory identifiers for player: ', sessionId)
    DropPlayer(sessionId, 'Failed to get your identifiers, please contact an administrator.')
    return
  end

  local userId = MySQL.insert.await('INSERT INTO users (license, discord_id, ip) VALUES (?, ?, ?)', { PLAYER_LICENSE, PLAYER_DISCORD_ID or NULL, PLAYER_IP })
  if not userId then
    ambitionsPrint.error('Failed to create user with license: ', PLAYER_LICENSE)
    DropPlayer(sessionId, 'Failed to create your user, please contact an administrator.')
    return
  end

  local ambitionsUser = userObject(sessionId, PLAYER_LICENSE)
  ambitionsUser:setIdentifiers(identifiers)

  CreateCharacter(sessionId, userId, ambitionsUser)
end

local function RetrieveUserData()

end

--- Check if the player is a new user or not and create a new user if needed or retrieve all the user data if the user already exists
local function CheckFirstSpawn()
  local SESSION_ID <const> = source
  local PLAYER_IDENTIFIERS <const> = identifiers.get(SESSION_ID)
  local PLAYER_LICENSE <const> = PLAYER_IDENTIFIERS.license

  if not PLAYER_LICENSE then
    ambitionsPrint.error('Failed to get player license for session id : ', SESSION_ID)
    DropPlayer(SESSION_ID, 'Failed to get your FiveM license, please contact an administrator.')
    return
  end

  MySQL.Async.fetchScalar('SELECT id FROM users WHERE license = ?', { PLAYER_LICENSE }, function(result)
    if not result then
      CreateUser(SESSION_ID, PLAYER_IDENTIFIERS)
    else
      ambitionsPrint.info('User found for license: ', PLAYER_LICENSE, ' id: ', result)
      RetrieveUserData()
    end
  end)
end


RegisterNetEvent('ambitions:server:checkFirstSpawn', function()
  CheckFirstSpawn()
end)