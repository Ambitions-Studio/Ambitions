local ambitionsPrint = require('shared.lib.log.print')
local identifiers = require('server.lib.player.identifiers')
local random = require('shared.lib.math.random')
local spawnConfig = require('config.multicharacter')
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
    position = {
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

  MySQL.insert.await('INSERT INTO characters (user_id, unique_id, `group`, ped_model, position_x, position_y, position_z, heading) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', { userId, characterData.uniqueId, characterData.group, characterData.pedModel, characterData.position.x, characterData.position.y, characterData.position.z, characterData.position.heading })

  local ambitionsCharacter = characterObject(sessionId, characterData.uniqueId, characterData)

  ambitionsUser:addCharacter(ambitionsCharacter)
  ambitionsUser:setCurrentCharacter(characterData.uniqueId)
  ambitionsUser:getCurrentCharacter():setActive(true)

  playerCache.add(sessionId, ambitionsUser)

  TriggerClientEvent('ambitions:client:playerLoaded', sessionId, characterData.pedModel, vector4(characterData.position.x, characterData.position.y, characterData.position.z, characterData.position.heading))
end

--- Create a new user in the database
---@param sessionId number The session id of the player
---@param identifiers table The identifiers of the player
local function CreateUser(sessionId, identifiers)
  local PLAYER_LICENSE <const> = identifiers.license
  local PLAYER_DISCORD_ID <const> = identifiers.discord
  local PLAYER_IP <const> = identifiers.ip

  if not PLAYER_LICENSE or not PLAYER_IP or not PLAYER_DISCORD_ID then
    ambitionsPrint.error('failed to get mandatory identifiers for player: ', sessionId)
    DropPlayer(sessionId, 'Failed to get your identifiers, please contact an administrator.')

    return
  end

  local userId = MySQL.insert.await('INSERT INTO users (license, discord_id, ip) VALUES (?, ?, ?)', { PLAYER_LICENSE, PLAYER_DISCORD_ID, PLAYER_IP })

  if not userId then
    ambitionsPrint.error('Failed to create user with license: ', PLAYER_LICENSE)
    DropPlayer(sessionId, 'Failed to create your user, please contact an administrator.')

    return
  end

  local ambitionsUser = userObject(sessionId, PLAYER_LICENSE)

  ambitionsUser:setIdentifiers(identifiers)

  CreateCharacter(sessionId, userId, ambitionsUser)
end

--- Load user character from database
---@param userId number The user ID from database
---@return table | nil characterData The character data or nil if not found
local function LoadUserCharacter(userId)
  local characterData = MySQL.single.await('SELECT * FROM characters WHERE user_id = ? LIMIT 1', { userId })

  if not characterData then
    ambitionsPrint.warning('No character found for user ID: ', userId)

    return nil
  end

  return {
    uniqueId = characterData.unique_id,
    group = characterData.group,
    pedModel = characterData.ped_model,
    position = {
      x = characterData.position_x,
      y = characterData.position_y,
      z = characterData.position_z,
      heading = characterData.heading
    },
    playtime = characterData.playtime or 0,
    lastPlayed = characterData.last_played,
    createdAt = characterData.created_at
  }
end

--- Create user and character objects from database data
---@param sessionId number The session ID of the player
---@param playerLicense string The player's license
---@param playerIdentifiers table All player identifiers
---@param characterData table The character data from database
---@return AmbitionsUserObject ambitionsUser The created user object
local function CreateUserObjects(sessionId, playerLicense, playerIdentifiers, characterData)
  local ambitionsUser = userObject(sessionId, playerLicense)

  ambitionsUser:setIdentifiers(playerIdentifiers)

  local ambitionsCharacter = characterObject(sessionId, characterData.uniqueId, characterData)

  ambitionsUser:addCharacter(ambitionsCharacter)
  ambitionsUser:setCurrentCharacter(characterData.uniqueId)
  ambitionsUser:getCurrentCharacter():setActive(true)

  return ambitionsUser
end

--- Finalize user loading and spawn player
---@param sessionId number The session ID of the player
---@param ambitionsUser AmbitionsUserObject The user object
local function FinalizeUserSpawn(sessionId, ambitionsUser)
  playerCache.add(sessionId, ambitionsUser)

  local currentCharacter = playerCache.get(sessionId):getCurrentCharacter()

  ambitionsPrint.success('Player ', GetPlayerName(sessionId), ' loaded successfully')

  TriggerClientEvent('ambitions:client:playerLoaded', sessionId, currentCharacter:getPedModel(), vector4(currentCharacter.position.x, currentCharacter.position.y, currentCharacter.position.z, currentCharacter.position.heading))
end

--- Retrieve existing user data from database and initialize objects
---@param sessionId number The session ID of the player
---@param userId number The user ID from database
---@param playerIdentifiers table All player identifiers
local function RetrieveUserData(sessionId, userId, playerIdentifiers)
  local characterData = LoadUserCharacter(userId)

  if not characterData then
    ambitionsPrint.error('Failed to retrieve your character, please contact an administrator.')
    DropPlayer(sessionId, 'Failed to retrieve your character, please contact an administrator.')

    return
  end

  local ambitionsUser = CreateUserObjects(sessionId, playerIdentifiers.license, playerIdentifiers, characterData)

  FinalizeUserSpawn(sessionId, ambitionsUser)
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
      RetrieveUserData(SESSION_ID, result, PLAYER_IDENTIFIERS)
    end
  end)
end


RegisterNetEvent('ambitions:server:checkFirstSpawn', function()
  CheckFirstSpawn()
end)