CreateThread(function()
  while not NetworkIsPlayerActive(PlayerId()) do
    Wait(100)
  end

  TriggerServerEvent('ambitions:server:checkFirstSpawn')
end)