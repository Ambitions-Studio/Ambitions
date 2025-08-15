local ambitionsPrint = require('shared.lib.log.print')

AddEventHandler('playerDropped', function(reason; resourceName, clientDropReason)
  ambitionsPrint.debug('Player ', GetPlayerName(source), ' dropped ( Reason : ', reason, ' Resource : ', resourceName, ' Client Drop Reason : ', clientDropReason, '.')
end)