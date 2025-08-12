--- Get all identifiers for a player and return them in a structured table
---@param playerId string|number The server ID of the player
---@return table identifiers Table containing all player identifiers organized by type
local function getAllIdentifiers(playerId)
    local rawIdentifiers = GetPlayerIdentifiers(playerId)
    if not rawIdentifiers then
        return {}
    end

    local identifiers = {}

    for i = 1, #rawIdentifiers do
        local identifier = rawIdentifiers[i]
        local colonPos = identifier:find(":")

        if colonPos then
            local identifierType = identifier:sub(1, colonPos - 1)
            identifiers[identifierType] = identifier
        end
    end

    return identifiers
end

--- Check if a player has a specific identifier type
---@param playerId string|number The server ID of the player
---@param identifierType string The type of identifier to check for
---@return boolean hasIdentifier Whether the player has this identifier type
local function hasIdentifier(playerId, identifierType)
    local identifier = GetPlayerIdentifierByType(playerId, identifierType)
    return identifier ~= nil and identifier ~= ""
end

local identifiers = {}

--- Get identifiers object for a player with direct access to all identifier types
---@param playerId string|number The server ID of the player
---@return table identifiers Object with direct access to .license, .steam, .discord, etc.
function identifiers.get(playerId)
    local obj = {
        --- Get all identifiers for this player
        ---@return table allIdentifiers Table with all identifiers organized by type
        getAll = function()
            return getAllIdentifiers(playerId)
        end,

        --- Check if this player has a specific identifier type
        ---@param identifierType string The type of identifier to check for
        ---@return boolean hasIdentifier Whether the player has this identifier type
        has = function(identifierType)
            return hasIdentifier(playerId, identifierType)
        end
    }

    setmetatable(obj, {
        __index = function(_, key)
            -- Si c'est une fonction définie, la retourner
            if rawget(obj, key) then
                return rawget(obj, key)
            end

            -- Sinon, récupérer l'identifiant du type demandé
            return GetPlayerIdentifierByType(playerId, key)
        end
    })

    return obj
end

return identifiers