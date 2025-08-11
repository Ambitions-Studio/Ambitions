local ambitionsPrint = require('lib.log.ambition-print')

local function FirstSpawn()

end

local function RegularSpawn()

end

local function CheckFirstSpawn()

end


AddEventHandler('ambitions:server:checkFirstSpawn', function()
  ambitionsPrint.debug('Checking first spawn')
  CheckFirstSpawn()
end)