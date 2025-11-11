MySQL.ready(function()
  amb.print.success(('^6[%s - %s] ^5 - Framework initialized'):format(GetInvokingResource():upper(), GetCurrentResourceName()))
  amb.print.info('💡 Tapez /testcallbacks en jeu pour tester le système de callbacks')
end)

RegisterCommand('testcallbacks', function(source)
  if source == 0 then
    print('[ERROR] Cette commande doit être exécutée en jeu, pas depuis la console serveur')
    return
  end

  amb.print.info('🧪 Lancement des tests callback pour le joueur', source, '(' .. GetPlayerName(source) .. ')')
  TriggerClientEvent('ambitions:test:startCallbackTest', source)
end, false)

-- Callback 1: Sans paramètres, retourne juste une info
amb.registerServerCallback('ambitions:test:getServerInfo', function(source)
  local serverInfo = {
    name = 'Ambitions Refactored Server',
    version = '2.0.0',
    timestamp = os.date('%Y-%m-%d %H:%M:%S'),
    players = #GetPlayers(),
    requestedBy = source
  }
  amb.print.info('Callback sans paramètres appelé par source', source, '- Retour:', serverInfo.name)
  return serverInfo
end)

-- Callback 2: Avec paramètres, effectue un calcul
amb.registerServerCallback('ambitions:test:calculateMath', function(source, operation, num1, num2)
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

  amb.print.info('Callback avec paramètres appelé par source', source, '- Calcul:', operation, num1, num2, '=', result)
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
  amb.print.success('=== RÉSULTATS DES TESTS CALLBACK ===')
  amb.print.info('Test 1 (sans paramètres):', testResults.test1 and 'SUCCESS' or 'FAILED')
  if testResults.test1 then
    amb.print.info('  - Server Name:', testResults.test1.name)
    amb.print.info('  - Timestamp:', testResults.test1.timestamp)
    amb.print.info('  - Players:', testResults.test1.players)
  end

  amb.print.info('Test 2 (avec paramètres):', testResults.test2 and 'SUCCESS' or 'FAILED')
  if testResults.test2 then
    amb.print.info('  - Opération:', testResults.test2.operation)
    amb.print.info('  - Calcul:', table.concat(testResults.test2.operands, ' x '), '=', testResults.test2.result)
  end

  if testResults.test1 and testResults.test2 then
    amb.print.success('🎉 TOUS LES TESTS CALLBACK ONT RÉUSSI!')
  else
    amb.print.error('❌ CERTAINS TESTS CALLBACK ONT ÉCHOUÉ!')
  end
end)