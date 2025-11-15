local hungerThread = nil
local thirstThread = nil

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
                end
            end
        end
    end)

    amb.print.success('Hunger degradation thread started')
end

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
                end
            end
        end
    end)

    amb.print.success('Thirst degradation thread started')
end

local function StopHungerDegradation()
    hungerThread = nil
    amb.print.info('Hunger degradation thread stopped')
end

local function StopThirstDegradation()
    thirstThread = nil
    amb.print.info('Thirst degradation thread stopped')
end

local function InitializeNeedsDegradation()
    StartHungerDegradation()
    StartThirstDegradation()
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
end)
