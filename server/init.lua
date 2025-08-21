local ambitionsPrint = require('Ambitions.shared.lib.log.print')

MySQL.ready(function()
  ambitionsPrint.success(('^6[%s - %s] ^5 - Framework initialized'):format(GetInvokingResource():upper(), GetCurrentResourceName()))
end)