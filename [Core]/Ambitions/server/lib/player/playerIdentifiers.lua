--- Define constants for identifier types.
local IDENTIFIER_TYPES <const> = {
    STEAM = 'steam',
    DISCORD = 'discord',
    LICENSE = 'license',
    LICENSE2 = 'license2',
    IP = 'ip',
    XBL = 'xbl',
    LIVE = 'live',
    FIVEM = 'fivem',
}

--- Retrieves all relevant identifiers for a player based on their server ID.
--- @class PlayerIdentifiers
--- @field name string The player's name.
--- @field identifier string The player's unique server identifier.
--- @field steam string|nil The player's Steam identifier.
--- @field discord string|nil The player's Discord identifier.
--- @field license string|nil The player's primary license identifier.
--- @field license2 string|nil The player's secondary license identifier (if applicable).
--- @field ip string|nil The player's IP address.
--- @field xbl string|nil The player's Xbox Live identifier.
--- @field live string|nil The player's Microsoft Live identifier.
--- @field fivem string|nil The player's FiveM identifier.

--- Retrieve the identifiers for a player.
--- @param source number The player's server ID.
--- @return PlayerIdentifiers|nil playerIdentifiers Table containing all player identifiers, or nil if player is not found.
function ABT.Player.GetPlayerIdentifier(source)
    -- local playerData <const> = PL.GetPlayerFromId(source)
    -- if not playerData then return nil end

    --- @type PlayerIdentifiers
    local PLAYER_IDENTIFIERS <const> = {
        name = GetPlayerName(source),
        -- identifier = playerData.identifier,
        steam = nil,
        discord = nil,
        license = nil,
        license2 = nil,
        ip = nil,
        xbl = nil,
        live = nil,
        fivem = nil,
    }

    -- Populate identifiers based on known types using pattern matching.
    for index = 0, GetNumPlayerIdentifiers(source) - 1 do
        local IDENTIFIER <const> = GetPlayerIdentifier(source, index)

        -- Assign values to the identifiers if they match a known type.
        PLAYER_IDENTIFIERS.steam = PLAYER_IDENTIFIERS.steam or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.STEAM .. ':(.+)$')
        PLAYER_IDENTIFIERS.discord = PLAYER_IDENTIFIERS.discord or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.DISCORD .. ':(.+)$')
        PLAYER_IDENTIFIERS.license = PLAYER_IDENTIFIERS.license or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.LICENSE .. ':(.+)$')
        PLAYER_IDENTIFIERS.license2 = PLAYER_IDENTIFIERS.license2 or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.LICENSE2 .. ':(.+)$')
        PLAYER_IDENTIFIERS.ip = PLAYER_IDENTIFIERS.ip or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.IP .. ':(.+)$')
        PLAYER_IDENTIFIERS.xbl = PLAYER_IDENTIFIERS.xbl or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.XBL .. ':(.+)$')
        PLAYER_IDENTIFIERS.live = PLAYER_IDENTIFIERS.live or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.LIVE .. ':(.+)$')
        PLAYER_IDENTIFIERS.fivem = PLAYER_IDENTIFIERS.fivem or IDENTIFIER:match('^' .. IDENTIFIER_TYPES.FIVEM .. ':(.+)$')
    end

    return PLAYER_IDENTIFIERS
end

return ABT.Player.GetPlayerIdentifier