MySQL.ready(function()
  amb.print.success(('^6[%s - %s] ^5 - Framework initialized'):format(GetInvokingResource():upper(), GetCurrentResourceName()))
  print('^6 █████╗ ███╗   ███╗██████╗ ██╗████████╗██╗ █████╗ ███╗  ██╗ ██████╗\n██╔══██╗████╗ ████║██╔══██╗██║╚══██╔══╝██║██╔══██╗████╗ ██║██╔════╝\n███████║██╔████╔██║██████╦╝██║   ██║   ██║██║  ██║██╔██╗██║╚█████╗ \n██╔══██║██║╚██╔╝██║██╔══██╗██║   ██║   ██║██║  ██║██║╚████║ ╚═══██╗\n██║  ██║██║ ╚═╝ ██║██████╦╝██║   ██║   ██║╚█████╔╝██║ ╚███║██████╔╝\n╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝   ╚═╝   ╚═╝ ╚════╝ ╚═╝  ╚══╝╚═════╝ ')
end)

RegisterCommand('testcallbacks', function(source)
  if source == 0 then
    print('[ERROR] Cette commande doit être exécutée en jeu, pas depuis la console serveur')
    return
  end

  ambitionsPrint.info('🧪 Lancement des tests callback pour le joueur', source, '(' .. GetPlayerName(source) .. ')')
  TriggerClientEvent('ambitions:test:startCallbackTest', source)
end, false)

-- Test du nouveau système de callback
local callback = require('server.lib.callback')

-- Callback 1: Sans paramètres, retourne juste une info
callback.register('ambitions:test:getServerInfo', function(source)
  local serverInfo = {
    name = 'Ambitions Refactored Server',
    version = '2.0.0',
    timestamp = os.date('%Y-%m-%d %H:%M:%S'),
    players = #GetPlayers(),
    requestedBy = source
  }
  ambitionsPrint.info('Callback sans paramètres appelé par source', source, '- Retour:', serverInfo.name)
  return serverInfo
end)

-- Callback 2: Avec paramètres, effectue un calcul
callback.register('ambitions:test:calculateMath', function(source, operation, num1, num2)
  local result
  if operation == 'add' then
    result = num1 + num2
  elseif operation == 'multiply' then
    result = num1 * num2
  elseif operation == 'subtract' then
    result = num1 - num2
  else
    result = 'unknown_operation'
  end

  ambitionsPrint.info('Callback avec paramètres appelé par source', source, '- Calcul:', operation, num1, num2, '=', result)
  return {
    operation = operation,
    operands = {num1, num2},
    result = result,
    timestamp = GetGameTimer(),
    requestedBy = source
  }
end)

-- Event pour recevoir les résultats des tests côté client
RegisterNetEvent('ambitions:test:sendTestResults', function(testResults)
  ambitionsPrint.success('=== RÉSULTATS DES TESTS CALLBACK ===')
  ambitionsPrint.info('Test 1 (sans paramètres):', testResults.test1 and 'SUCCESS' or 'FAILED')
  if testResults.test1 then
    ambitionsPrint.info('  - Server Name:', testResults.test1.name)
    ambitionsPrint.info('  - Timestamp:', testResults.test1.timestamp)
    ambitionsPrint.info('  - Players:', testResults.test1.players)
  end

  ambitionsPrint.info('Test 2 (avec paramètres):', testResults.test2 and 'SUCCESS' or 'FAILED')
  if testResults.test2 then
    ambitionsPrint.info('  - Opération:', testResults.test2.operation)
    ambitionsPrint.info('  - Calcul:', table.concat(testResults.test2.operands, ' x '), '=', testResults.test2.result)
  end

  if testResults.test1 and testResults.test2 then
    ambitionsPrint.success('🎉 TOUS LES TESTS CALLBACK ONT RÉUSSI!')
  else
    ambitionsPrint.error('❌ CERTAINS TESTS CALLBACK ONT ÉCHOUÉ!')
  end
end)