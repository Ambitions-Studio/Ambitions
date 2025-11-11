-- Écouter le signal de démarrage des tests
RegisterNetEvent('ambitions:test:startCallbackTest', function()
    amb.print.info('🧪 Démarrage des tests callback refactorisés côté client...')

    local testResults = {
        test1 = nil,
        test2 = nil
    }

    local testsCompleted = 0
    local totalTests = 2

    local function checkAllTestsCompleted()
        testsCompleted = testsCompleted + 1
        if testsCompleted >= totalTests then
            amb.print.success('✅ Tests côté client terminés - Envoi des résultats au serveur')
            TriggerServerEvent('ambitions:test:sendTestResults', testResults)
        end
    end

    -- Test 1: Callback sans paramètres avec nouvelle API
    amb.print.info('📞 Test 1: Appel callback.trigger sans paramètres...')
    amb.triggerServerCallback('ambitions:test:getServerInfo', false, function(serverInfo)
        if serverInfo and serverInfo.name then
            amb.print.success('✅ Test 1 réussi - Info serveur reçue:', serverInfo.name, 'v' .. serverInfo.version)
            testResults.test1 = serverInfo
        else
            amb.print.error('❌ Test 1 échoué - Pas de réponse du serveur')
            testResults.test1 = false
        end
        checkAllTestsCompleted()
    end)

    -- Test 2: Callback avec paramètres avec nouvelle API
    amb.print.info('📞 Test 2: Appel callback.trigger avec paramètres (5 x 7)...')
    amb.triggerServerCallback('ambitions:test:calculateMath', {delay = 1000}, function(mathResult)
        if mathResult and mathResult.result then
            amb.print.success('✅ Test 2 réussi - Calcul reçu:', mathResult.result, 'par source', mathResult.requestedBy)
            testResults.test2 = mathResult
        else
            amb.print.error('❌ Test 2 échoué - Pas de résultat de calcul')
            testResults.test2 = false
        end
        checkAllTestsCompleted()
    end, 'multiply', 5, 7)

    amb.print.info('⏳ Tests en cours d\'exécution avec la nouvelle API...')
end)