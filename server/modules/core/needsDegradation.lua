local hungerThread = nil
local thirstThread = nil
local healthDecayThread = nil

--- Starts the health decay thread that damages players with empty hunger or thirst
local function StartHealthDecay()
    if healthDecayThread then
        return
    end

    healthDecayThread = true

    CreateThread(function()
        while healthDecayThread do
            Wait(needsConfig.degradation.healthDecay.interval)

            local players = amb.cache.getAllPlayers()

            for sessionId, userObject in pairs(players) do
                if userObject.currentCharacter and userObject.currentCharacter.isCharacterActive() then
                    local hunger = userObject.currentCharacter.getNeed('hunger') or 100
                    local thirst = userObject.currentCharacter.getNeed('thirst') or 100
                    local isDead = userObject.currentCharacter.getIsDead()

                    if not isDead and (hunger <= 0 or thirst <= 0) then
                        local damageAmount = needsConfig.degradation.healthDecay.amount
                        if hunger <= 0 and thirst <= 0 then
                            damageAmount = damageAmount * 2
                        end
                        TriggerClientEvent('ambitions-hud:client:damagePlayer', sessionId, damageAmount)
                    end
                end
            end
        end
    end)

    amb.print.success('Health decay thread started')
end

--- Stops the health decay thread
local function StopHealthDecay()
    healthDecayThread = nil
    amb.print.info('Health decay thread stopped')
end

--- Starts the hunger degradation thread that decreases hunger over time
local function StartHungerDegradation()
    if not needsConfig.degradation.hunger.enabled then
        return
    end

    if hungerThread then
        return
    end

    hungerThread = true

    CreateThread(function()
        while hungerThread do
            Wait(needsConfig.degradation.hunger.interval)

            local players = amb.cache.getAllPlayers()

            for sessionId, userObject in pairs(players) do
                if userObject.currentCharacter and userObject.currentCharacter.isCharacterActive() then
                    userObject.currentCharacter.getNeedsManager().decay('hunger', needsConfig.degradation.hunger.amount)
                    local newValue = userObject.currentCharacter.getNeed('hunger')
                    TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'hunger', newValue)
                end
            end
        end
    end)

    amb.print.success('Hunger degradation thread started')
end

--- Starts the thirst degradation thread that decreases thirst over time
local function StartThirstDegradation()
    if not needsConfig.degradation.thirst.enabled then
        return
    end

    if thirstThread then
        return
    end

    thirstThread = true

    CreateThread(function()
        while thirstThread do
            Wait(needsConfig.degradation.thirst.interval)

            local players = amb.cache.getAllPlayers()

            for sessionId, userObject in pairs(players) do
                if userObject.currentCharacter and userObject.currentCharacter.isCharacterActive() then
                    userObject.currentCharacter.getNeedsManager().decay('thirst', needsConfig.degradation.thirst.amount)
                    local newValue = userObject.currentCharacter.getNeed('thirst')
                    TriggerClientEvent('ambitions-hud:client:updateNeed', sessionId, 'thirst', newValue)
                end
            end
        end
    end)

    amb.print.success('Thirst degradation thread started')
end

--- Stops the hunger degradation thread
local function StopHungerDegradation()
    hungerThread = nil
    amb.print.info('Hunger degradation thread stopped')
end

--- Stops the thirst degradation thread
local function StopThirstDegradation()
    thirstThread = nil
    amb.print.info('Thirst degradation thread stopped')
end

--- Initializes all needs degradation threads
local function InitializeNeedsDegradation()
    StartHungerDegradation()
    StartThirstDegradation()
    StartHealthDecay()
    amb.print.success('Needs degradation system initialized')
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    InitializeNeedsDegradation()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    StopHungerDegradation()
    StopThirstDegradation()
    StopHealthDecay()
end)
