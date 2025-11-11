--- Get identifiers object for a player with direct access to all identifier types
---@param playerId string|number The server ID of the player
---@return table identifiers Object with direct access to .license, .steam, .discord, etc. (values only, no prefixes)
function amb.getPlayerIdentifers(playerId)
    local identifiers = {}

    identifiers.name = GetPlayerName(playerId)

    for _, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        local identifierType, identifierValue = identifier:match("^([^:]+):(.+)$")

        if identifierType and identifierValue then
            identifiers[identifierType] = identifierValue
        end
    end

    return identifiers
end