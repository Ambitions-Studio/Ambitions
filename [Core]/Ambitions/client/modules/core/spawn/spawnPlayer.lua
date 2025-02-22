local debug = import('config.shared.config_debug')
local spawn = import('config.shared.config_spawn')

--- Set the default clothes for the default player model
---@param ped number Ped ID
local function SetDefaultClothes(ped)
    for i = 0, 11 do
        SetPedComponentVariation(ped, i, 0, 0, 4)
    end

    for i = 0, 7 do
        ClearPedProp(ped, i)
    end
end

-- Spawn the player at the necessary position
---@param characterData table The character data
local function CreateAmbitionsPlayer(characterData)

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(100)
    end

    local pedModel = characterData.ped_model
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(500)
    end

    local playerPed = PlayerPedId()
    SetPlayerModel(PlayerId(), spawn.DEFAULT_MODEL)
    playerPed = PlayerPedId()
    SetDefaultClothes(playerPed)

    local spawnPosition = vector3(characterData.position_x, characterData.position_y, characterData.position_z)
    local spawnHeading = characterData.heading

    local status = characterData.status
    local spawnHealth = status.health
    local spawnArmor = status.armor
    local isDead = characterData.isDead
    ABT.Print.Log(2, 'isDead:', isDead)

    if isDead == 1 then
        spawnHealth = 0
        spawnArmor = 0
    end

    SetEntityCoords(playerPed, spawnPosition.x, spawnPosition.y, spawnPosition.z, false, false, false, true)
    SetEntityHeading(playerPed, spawnHeading)
    SetEntityHealth(playerPed, spawnHealth)
    SetPedArmour(playerPed, spawnArmor)

    SetModelAsNoLongerNeeded(spawn.DEFAULT_MODEL)

    if isDead == 1 then
        FreezeEntityPosition(playerPed, true)
    else
        FreezeEntityPosition(playerPed, false)
        SetEntityInvincible(playerPed, false)
        SetPlayerControl(PlayerId(), true)
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    DoScreenFadeIn(500)

    if debug.Spawn.DebugClient then
        ABT.Print.Log(2, 'Player successfully spawned at position :', spawnPosition.x, spawnPosition.y, spawnPosition.z)
    end
end

-- RegisterNetEvent('ambitions:client:firstSpawn', function()
--     if debug.Spawn.DebugClient then
--         ABT.Print.Log(1, 'First spawn detected. Initializing new player...')
--     end

--     CreateAmbitionsPlayer(nil, true)
-- end)

-- RegisterNetEvent('ambitions:client:loadCharacter', function(characterData)
--     if debug.Spawn.DebugClient then
--         ABT.Print.Log(1, 'Loading character data ...', characterData)
--     end

--     CreateAmbitionsPlayer(characterData, false)
-- end)

RegisterNetEvent('ambitions:playerLoaded', function(characterData, amberPlayer)

    ABT.PlayerData = amberPlayer

    if isFirstSpawn then
        if debug.Spawn.DebugClient then
            ABT.Print.Log(1, 'First spawn detected. Initializing new player...')
        end
    else
        if debug.Spawn.DebugClient then
            ABT.Print.Log(1, 'Loading character data ...', characterData)
        end
    end
    
    CreateAmbitionsPlayer(characterData)
    ABT.SetPlayerData('ped', PlayerPedId())
    ABT.SetPlayerData('dead', characterData.isDead)
    ABT.PlayerLoaded = true
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end

    TriggerServerEvent('ambitions:server:spawnedPlayer')
end)