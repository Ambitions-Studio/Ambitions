--- Retrieve the identifiers for a player.
--- @param source number The player's server ID.
--- @return PlayerIdentifiers|nil identifiers Table containing all player identifiers, or nil if player is not found.
function ABT.Player.GetPlayerIdentifier(source)
    local identifiers = {}
<<<<<<< HEAD
    identifiers['name'] = GetPlayerName(source)
    for k,v in pairs(GetPlayerIdentifiers(source)) do
        identifiers[v:match("^(%w+)")] = v:match(":(.+)$")
    end

=======

    identifiers['name'] = GetPlayerName(source)
    for _,v in pairs(GetPlayerIdentifiers(source)) do
        identifiers[v:match("^(%w+)")] = v:match(":(.+)$")
    end

    ABT.Print.Log("Player identifiers: ", identifiers)
>>>>>>> fc868f72a2052e1ed94c1ea04fc0759cc09fe045
    return identifiers
end

return ABT.Player.GetPlayerIdentifier