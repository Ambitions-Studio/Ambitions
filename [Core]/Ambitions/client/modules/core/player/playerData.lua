--- Get PlayerData from the server
---@return table PlayerData
function ABT.GetPlayerData()
    return ABT.PlayerData
end

--- Set Player Data from the server
--- @param key string The key of the data
--- @param value any The value of the data
--- @return void
function ABT.SetPlayerData(key, value)
    local currentData = ABT.PlayerData[key]
    ABT.PlayerData[key] = value
    if key ~= "inventory" and key ~= "loadout" then
        if type(value) == "table" or value ~= currentData then
            TriggerEvent("ambitions:setPlayerData", key, value, currentData)
        end
    end
end


function ABT.GetAccount(account)
    for i = 1, #ABT.PlayerData.currentCharacter.accounts, 1 do
        if ABT.PlayerData.currentCharacter.accounts[i].name == account then
            return ABT.PlayerData.currentCharacter.accounts[i]
        end
    end
    return nil
end