local ambitionsPrint = require('lib.log.ambition-print')

local function SpawnCharacter()
  DoScreenFadeOut(500)
  while not IsScreenFadedOut() do
    Wait(100)
  end

  ambitionsPrint.debug('Fading out')

  local playerPed = PlayerPedId()
  local spawnCoords = vector3(0.0, 0.0, 70.0)
  local spawnHeading = 180.0

  SetEntityCoords(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
  SetEntityHeading(playerPed, spawnHeading)

  ambitionsPrint.debug('Setting player coords')

  FreezeEntityPosition(playerPed, false)
  SetEntityInvincible(playerPed, false)
  SetPlayerControl(PlayerId(), true)

  ambitionsPrint.debug('Fading in')

  DoScreenFadeIn(500)

  ambitionsPrint.debug('Spawned character')
end

CreateThread(function()
  while not NetworkIsPlayerActive(PlayerId()) do
    Wait(100)
  end

  SpawnCharacter()
end)