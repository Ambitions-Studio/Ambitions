--- Get identifiers object for a player with direct access to all identifier types
---@param playerId string|number The server ID of the player
---@return table identifiers Object with direct access to .license, .steam, .discord, etc. (values only, no prefixes)
function amb.getPlayerIdentifers(playerId)
    local identifiers = {}

    identifiers['name'] = GetPlayerName(playerId)
    for _,v in pairs(GetPlayerIdentifiers(playerId)) do
        identifiers[v:match("^(%w+)")] = v:match(":(.+)$")
    end

    amb.print.debug("player's identifiers : ", identifiers)
    return identifiers
end