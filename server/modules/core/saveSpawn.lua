local ambitionsPrint = require('lib.log.ambition-print')
local identifiers = require('server.lib.player.identifiers')

local function FirstSpawn()

end

local function RegularSpawn()

end

local function CheckFirstSpawn()
  local playerIdentifiers = identifiers.get(source).getAll()
  ambitionsPrint.debug('Player identifiers: ' .. playerIdentifiers)
end


AddEventHandler('ambitions:server:checkFirstSpawn', function()
  ambitionsPrint.debug('Checking first spawn')
  CheckFirstSpawn()
end)