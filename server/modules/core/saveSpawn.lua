local ambitionsPrint = require('shared.lib.log.print')
local identifiers = require('server.lib.player.identifiers')

local function FirstSpawn()

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
      ambitionsPrint.error('Failed to get User Id for license: ', PLAYER_LICENSE)
      DropPlayer(SESSION_ID, 'Failed to get your user id, please contact an administrator.')
      return
    end
    ambitionsPrint.debug('User Id for license: ', PLAYER_LICENSE, ' is: ', result)
  end)
end


AddEventHandler('ambitions:server:checkFirstSpawn', function()
  ambitionsPrint.debug('Checking first spawn')
  CheckFirstSpawn()
end)