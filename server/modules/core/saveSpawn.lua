local ambitionsPrint = require('shared.lib.log.print')
local identifiers = require('server.lib.player.identifiers')
local random = require('shared.lib.math.random')
local spawnConfig = require('config.spawn')

local function GenerateUniqueId()
end

--- Get a valid unique id for the character
---@return string | nil uniqueId The unique id or nil if failed to generate a valid unique id
local function GetValidUniqueId()
  local uniqueId
  local attempts = 0
  local maxAttempts = 10

  repeat
    attempts += 1
    if attempts > maxAttempts then
      ambitionsPrint.error('Failed to generate a valid unique id for player: ', sessionId, ' after ', maxAttempts, ' attempts')
      return nil
    end

    uniqueId = random.alphanumeric(6)
  until not isUniqueIdInUse(uniqueId)

  ambitionsPrint.info('Generated valid unique id: ', uniqueId)

  return uniqueId
end

--- Create a new character in the database
---@param sessionId number The session id of the player
---@param userId number The user id of the player
local function CreateCharacter(sessionId, userId)
  GetValidUniqueId()
end

--- Create a new user in the database
---@param sessionId number The session id of the player
---@param identifiers table The identifiers of the player
local function CreateUser(sessionId, identifiers)
  local PLAYER_LICENSE <const> = identifiers.license
  local PLAYER_DISCORD_ID <const> = identifiers.discord
  local PLAYER_IP <const> = identifiers.ip

  if not PLAYER_LICENSE or not PLAYER_DISCORD_ID or not PLAYER_IP then
    ambitionsPrint.error('failed to get mandatory identifiers for player: ', sessionId)
    DropPlayer(sessionId, 'Failed to get your identifiers, please contact an administrator.')
    return
  end

  MySQL.Async.insert('INSERT INTO users (license, discord_id, ip) VALUES (?, ?, ?)', { PLAYER_LICENSE, PLAYER_DISCORD_ID, PLAYER_IP }, function(userId)
    if not userId then
      ambitionsPrint.error('Failed to create user with license: ', PLAYER_LICENSE)
      DropPlayer(sessionId, 'Failed to create your user, please contact an administrator.')
      return
    end

    ambitionsPrint.info('User with license : ', PLAYER_LICENSE, ' has been created, id: ', userId)
    CreateCharacter(sessionId, userId)
  end)
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