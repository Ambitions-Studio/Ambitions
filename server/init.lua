local ambitionsPrint = require('shared.lib.log.print')

MySQL.ready(function()
  ambitionsPrint.debug(('^6[%s - %s] ^5 - Framework initialized'):format(GetCurrentResourceName(), GetCurrentResourceName()))
end)