--- Get all identifiers for a player and return them in a structured table with values only
---@param playerId string|number The server ID of the player
---@return table identifiers Table containing all player identifiers with only the values (no prefixes)
local function getAllIdentifiers(playerId)
    local rawIdentifiers = GetPlayerIdentifiers(playerId)
    if not rawIdentifiers then
        return {}
    end

    local identifiers = {}

    for i = 1, #rawIdentifiers do
        local identifier = rawIdentifiers[i]
        local identifierType, identifierValue = identifier:match("^([^:]+):(.+)$")
        
        if identifierType and identifierValue then
            identifiers[identifierType] = identifierValue
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
---@return table identifiers Object with direct access to .license, .steam, .discord, etc. (values only, no prefixes)
function identifiers.get(playerId)
    local obj = {
        --- Get all identifiers for this player
        ---@return table allIdentifiers Table with all identifiers organized by type (values only)
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

            -- Sinon, récupérer l'identifiant du type demandé et extraire la valeur
            local fullIdentifier = GetPlayerIdentifierByType(playerId, key)
            if not fullIdentifier then
                return nil
            end
            
            local _, identifierValue = fullIdentifier:match("^([^:]+):(.+)$")
            return identifierValue or fullIdentifier
        end
    })

    return obj
end

return identifiers