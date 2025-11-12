amb.cache = {}

local cache = {}

--- Add a player to the cache
---@param sessionId number The session ID of the player
---@param userObject AmbitionsUserObject The user object to cache
---@return boolean success Whether the operation was successful
function amb.cache.addPlayer(sessionId, userObject)
  if not sessionId or not userObject then
    amb.print.error('Invalid parameters for amb.cache.addPlayer')
    return false
  end

  cache[sessionId] = userObject

  return true
end

--- Get a player from the cache
---@param sessionId number The session ID of the player
---@return AmbitionsUserObject | nil userObject The user object or nil if not found
function amb.cache.getPlayer(sessionId)
  return cache[sessionId]
end

--- Remove a player from the cache
---@param sessionId number The session ID of the player
---@return boolean success Whether the operation was successful
function amb.cache.removePlayer(sessionId)
  if cache[sessionId] then
    cache[sessionId] = nil

    return true
  end

  amb.print.warning('Attempted to remove non-existent player from cache: ', sessionId)

  return false
end

--- Check if a player exists in the cache
---@param sessionId number The session ID of the player
---@return boolean exists Whether the player exists in cache
function amb.cache.doesPlayerExist(sessionId)
  return cache[sessionId] ~= nil
end

--- Get all cached players
---@return table players All cached players indexed by sessionId
function amb.cache.getAllPlayers()
  return cache
end

--- Get the count of cached players
---@return number count Number of players currently cached
function amb.cache.getPlayerCount()
  local count = 0

  for _ in pairs(cache) do
    count = count + 1
  end

  return count
end

--- Get all online player session IDs
---@return table sessionIds Array of all cached session IDs
function amb.cache.getAllPlayersSessionIds()
  local sessionIds = {}

  for sessionId, _ in pairs(cache) do
    table.insert(sessionIds, sessionId)
  end

  return sessionIds
end

--- Clear the entire cache (use with caution)
function amb.cache.clearPlayerCache()
  cache = {}
  amb.print.warning('Player cache has been cleared')
end

--- Get cache statistics
---@return table stats Cache statistics
function amb.cache.getPlayerCacheStats()
  local stats = {
    totalPlayers = amb.cache.getPlayerCount,
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