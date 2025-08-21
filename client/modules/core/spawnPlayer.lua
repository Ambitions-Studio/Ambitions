local multicharacterConfig = require('Ambitions.config.multicharacter')

--- Set the default clothes for the player
---@param ped number The ped of the player
local function SetDefaultClothes(ped)
  for i = 0, 11 do
      SetPedComponentVariation(ped, i, 0, 0, 4)
  end

  for i = 0, 7 do
      ClearPedProp(ped, i)
  end
end

--- Spawn the player in the world with the given parameters
---@param pedModel string The model of the player
---@param positionX number The x coordinate of the player
---@param positionY number The y coordinate of the player
---@param positionZ number The z coordinate of the player
---@param heading number The heading of the player
local function SpawnAmbitionsPlayer(pedModel, positionX, positionY, positionZ, heading)
  DoScreenFadeOut(500)
  while not IsScreenFadedOut() do
      Wait(100)
  end

  RequestModel(pedModel)
  while not HasModelLoaded(pedModel) do
      Wait(500)
  end

  SetPlayerModel(PlayerId(), pedModel)
  local playerPed = PlayerPedId()
  SetDefaultClothes(playerPed)

  SetEntityCoords(playerPed, positionX, positionY, positionZ, false, false, false, true)
  SetEntityHeading(playerPed, heading)
  SetEntityHealth(playerPed, 200)
  SetPedArmour(playerPed, 100)

  SetModelAsNoLongerNeeded(pedModel)

  FreezeEntityPosition(playerPed, false)
  SetEntityInvincible(playerPed, false)
  SetPlayerControl(PlayerId(), true)

  ShutdownLoadingScreen()
  ShutdownLoadingScreenNui()

  DoScreenFadeIn(500)
end

RegisterNetEvent('ambitions:client:playerLoaded', function(pedModel, spawnCoords)
  SpawnAmbitionsPlayer(pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w)
end)

CreateThread(function()
  while not multicharacterConfig.useMulticharacter do
    Wait(100)

    if NetworkIsPlayerActive(PlayerId()) then
      TriggerServerEvent('ambitions:server:checkFirstSpawn')
      break
    end
  end
end)