RegisterNetEvent('ambitions:setAccountMoney', function(account)
    for i = 1, #ABT.PlayerData.currentCharacter.accounts do
        if ABT.PlayerData.currentCharacter.accounts[i].name == account.name then
            ABT.PlayerData.currentCharacter.accounts[i] = account
            break
        end
    end

    ABT.SetPlayerData('accounts', ABT.PlayerData.currentCharacter.accounts)
end)

RegisterNetEvent('ambitions:setGroup', function(group)
    ABT.SetPlayerData('group', group)
end)


RegisterNetEvent('ambitions:test:showData', function()
    ABT.Print.Log(5, 'Player Data', ABT.PlayerData)
end)