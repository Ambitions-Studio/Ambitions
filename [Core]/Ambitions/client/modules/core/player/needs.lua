local interval = import('config.client.config_needs')

RegisterNetEvent('ambitions:client:StartNeedsThread', function()
    CreateThread(function()
        ABT.Print.Log(2, 'Starting needs thread...')

        while not ABT.PlayerLoaded do
            Wait(1000)
        end

        while ABT.PlayerLoaded do
            local hunger = ABT.Callback.await('ambitions:server:getNeed', nil, 'hunger')
            local thirst = ABT.Callback.await('ambitions:server:getNeed', nil, 'thirst')

            if hunger then
                ABT.Print.Log(2, ('Current Hunger: %s'):format(hunger))
                if hunger > 0 then
                    ABT.Callback.await('ambitions:server:removeNeed', nil, 'hunger', interval.HungerNeedDecrease)
                else
                    ABT.Print.Log(3, 'Hunger is already at minimum value.')
                end
            end

            if thirst then
                ABT.Print.Log(2, ('Current Thirst: %s'):format(thirst))
                if thirst > 0 then
                    ABT.Callback.await('ambitions:server:removeNeed', nil, 'thirst', interval.ThirstNeedDecrease)
                else
                    ABT.Print.Log(3, 'Thirst is already at minimum value.')
                end
            end

            Wait(interval.NeedsInterval)
        end
    end)
end)