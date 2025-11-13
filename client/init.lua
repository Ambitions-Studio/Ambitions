local ambitionsPrint = require('shared.lib.log.print')

-- Test du nouveau système de callback côté client
local callback = require('client.lib.callback')

-- Écouter le signal de démarrage des tests
RegisterNetEvent('ambitions:test:startCallbackTest', function()
    ambitionsPrint.info('🧪 Démarrage des tests callback refactorisés côté client...')

    local testResults = {
        test1 = nil,
        test2 = nil
    }

    local testsCompleted = 0
    local totalTests = 2

    local function checkAllTestsCompleted()
        testsCompleted = testsCompleted + 1
        if testsCompleted >= totalTests then
            ambitionsPrint.success('✅ Tests côté client terminés - Envoi des résultats au serveur')
            TriggerServerEvent('ambitions:test:sendTestResults', testResults)
        end
    end

    -- Test 1: Callback sans paramètres avec nouvelle API
    ambitionsPrint.info('📞 Test 1: Appel callback.trigger sans paramètres...')
    callback.trigger('ambitions:test:getServerInfo', false, function(serverInfo)
        if serverInfo and serverInfo.name then
            ambitionsPrint.success('✅ Test 1 réussi - Info serveur reçue:', serverInfo.name, 'v' .. serverInfo.version)
            testResults.test1 = serverInfo
        else
            ambitionsPrint.error('❌ Test 1 échoué - Pas de réponse du serveur')
            testResults.test1 = false
        end
        checkAllTestsCompleted()
    end)

    -- Test 2: Callback avec paramètres avec nouvelle API
    ambitionsPrint.info('📞 Test 2: Appel callback.trigger avec paramètres (5 x 7)...')
    callback.trigger('ambitions:test:calculateMath', {delay = 1000}, function(mathResult)
        if mathResult and mathResult.result then
            ambitionsPrint.success('✅ Test 2 réussi - Calcul reçu:', mathResult.result, 'par source', mathResult.requestedBy)
            testResults.test2 = mathResult
        else
            ambitionsPrint.error('❌ Test 2 échoué - Pas de résultat de calcul')
            testResults.test2 = false
        end
        checkAllTestsCompleted()
    end, 'multiply', 5, 7)

    ambitionsPrint.info('⏳ Tests en cours d\'exécution avec la nouvelle API...')
end)