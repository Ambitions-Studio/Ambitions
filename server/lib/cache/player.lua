local ambitionsPrint = require('shared.lib.log.print')

local cache = {}

local playerCache = {}

--- Add a player to the cache
---@param sessionId number The session ID of the player
---@param userObject AmbitionsUserObject The user object to cache
---@return boolean success Whether the operation was successful
function playerCache.add(sessionId, userObject)
  if not sessionId or not userObject then
    ambitionsPrint.error('Invalid parameters for playerCache.add')
    return false
  end

  cache[sessionId] = userObject
  ambitionsPrint.debug('Player added to cache: ', sessionId)
  return true
end

--- Get a player from the cache
---@param sessionId number The session ID of the player
---@return AmbitionsUserObject | nil userObject The user object or nil if not found
function playerCache.get(sessionId)
  return cache[sessionId]
end

--- Remove a player from the cache
---@param sessionId number The session ID of the player
---@return boolean success Whether the operation was successful
function playerCache.remove(sessionId)
  if cache[sessionId] then
    cache[sessionId] = nil
    ambitionsPrint.debug('Player removed from cache: ', sessionId)
    return true
  end
  ambitionsPrint.warning('Attempted to remove non-existent player from cache: ', sessionId)
  return false
end

--- Check if a player exists in the cache
---@param sessionId number The session ID of the player
---@return boolean exists Whether the player exists in cache
function playerCache.exists(sessionId)
  return cache[sessionId] ~= nil
end

--- Get all cached players
---@return table players All cached players indexed by sessionId
function playerCache.getAll()
  return cache
end

--- Get the count of cached players
---@return number count Number of players currently cached
function playerCache.getCount()
  local count = 0
  for _ in pairs(cache) do
    count = count + 1
  end
  return count
end

--- Get all online player session IDs
---@return table sessionIds Array of all cached session IDs
function playerCache.getAllSessionIds()
  local sessionIds = {}
  for sessionId, _ in pairs(cache) do
    table.insert(sessionIds, sessionId)
  end
  return sessionIds
end

--- Clear the entire cache (use with caution)
function playerCache.clear()
  cache = {}
  ambitionsPrint.warning('Player cache has been cleared')
end

--- Get cache statistics
---@return table stats Cache statistics
function playerCache.getStats()
  local stats = {
    totalPlayers = playerCache.getCount(),
    onlinePlayers = 0,
    totalCharacters = 0,
    activePlayers = 0
  }

  for _, user in pairs(cache) do
    if user:isUserOnline() then
      stats.onlinePlayers = stats.onlinePlayers + 1
    end

    stats.totalCharacters = stats.totalCharacters + user:getCharacterCount()

    if user:getCurrentCharacter() and user:getCurrentCharacter():isCharacterActive() then
      stats.activePlayers = stats.activePlayers + 1
    end
  end

  return stats
end

return playerCache