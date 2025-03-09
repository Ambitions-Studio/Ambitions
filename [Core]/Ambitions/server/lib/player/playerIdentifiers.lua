--- Retrieve the identifiers for a player.
--- @param source number The player's server ID.
--- @return table identifiers Table containing all player identifiers, or nil if player is not found.
function ABT.Player.GetPlayerIdentifier(source)
    local identifiers = {}

    identifiers['name'] = GetPlayerName(source)
    for _,v in pairs(GetPlayerIdentifiers(source)) do
        identifiers[v:match("^(%w+)")] = v:match(":(.+)$")
    end

    return identifiers
end

return ABT.Player.GetPlayerIdentifier
