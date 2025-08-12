local ambitionsPrint = require('shared.lib.log.print')
local identifiers = require('server.lib.player.identifiers')

local function FirstSpawn(sessionId, identifiers)
  local PLAYER_LICENSE <const> = identifiers.license
  local PLAYER_DISCORD_ID <const> = identifiers.discord
  local PLAYER_IP <const> = identifiers.ip

  if not PLAYER_LICENSE or not PLAYER_DISCORD_ID or not PLAYER_IP then
    ambitionsPrint.error('failed to get mandatory identifiers for player: ', sessionId)
    DropPlayer(sessionId, 'Failed to get your identifiers, please contact an administrator.')
    return
  end

  MySQL.Async.insert('INSERT INTO users (license, discord_id, ip) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP', { PLAYER_LICENSE, PLAYER_DISCORD_ID, PLAYER_IP }, function(userId)
    if not userId then
      ambitionsPrint.error('Failed to create user with license: ', PLAYER_LICENSE)
      DropPlayer(sessionId, 'Failed to create your user, please contact an administrator.')
      return
    end

    ambitionsPrint.info('User with license : ', PLAYER_LICENSE, ' has been created, id: ', userId)
  end)
end

local function RegularSpawn()

end

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
      FirstSpawn(SESSION_ID, PLAYER_IDENTIFIERS)
    else
      ambitionsPrint.info('User found for license: ', PLAYER_LICENSE, ' id: ', result)
    end
  end)
end


RegisterNetEvent('ambitions:server:checkFirstSpawn', function()
  CheckFirstSpawn()
end)