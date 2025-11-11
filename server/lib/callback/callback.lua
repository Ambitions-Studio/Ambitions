-- Server callback state management
local serverCallbacks = {
    handlers = {},
    pendingRequests = {},
    playerValidation = {},
    config = {
        defaultTimeout = GetConvarInt('ambitions:callbackTimeout', 180000), -- 3 minutes
        maxConcurrentCallsPerPlayer = GetConvarInt('ambitions:callbackPlayerLimit', 25)
    }
}

-- Network event constants
local SERVER_EVENTS = {
    INCOMING_CALL = 'ambitions:callback:server:call',
    RESPONSE = 'ambitions:callback:server:response'
}

--- Get the current resource context
---@return string resourceName Current resource name
local function getResourceContext()
    return GetCurrentResourceName()
end

--- Generate unique request identifier for server callbacks
---@param callbackName string The callback being called
---@param playerId number The target player ID
---@return string requestId Unique request identifier
local function generateServerRequestId(callbackName, playerId)
    local timestamp = GetGameTimer()
    local random = amb.math.randomAlphanumeric(10)

    return ('%s:%d:%d:%s'):format(callbackName, playerId, timestamp, random)
end

--- Validate that a player exists and is connected
---@param playerId number The player ID to validate
---@return boolean valid Whether the player is valid
---@return string|nil reason Reason for invalidity if applicable
local function validatePlayerConnection(playerId)
    if not DoesPlayerExist(playerId) then
        return false, 'player_not_found'
    end

    local playerPing = GetPlayerPing(playerId)

    if playerPing <= 0 then
        return false, 'player_disconnected'
    end

    return true, nil
end

--- Check concurrent call limits per player
---@param playerId number The player making the request
---@return boolean allowed Whether the call is allowed
local function checkPlayerCallLimit(playerId)
    local activeCallsForPlayer = 0

    for requestId, request in pairs(serverCallbacks.pendingRequests) do
        if request.playerId == playerId then
            activeCallsForPlayer = activeCallsForPlayer + 1
        end
    end

    if activeCallsForPlayer >= serverCallbacks.config.maxConcurrentCallsPerPlayer then
        amb.print.warning('Player', playerId, 'exceeded concurrent callback limit:', activeCallsForPlayer)
        return false
    end

    return true
end

--- Execute server callback handler with error protection
---@param handler function The callback handler function
---@param source number The player source
---@param ... any Arguments to pass to the handler
---@return boolean success Whether execution was successful
---@return any ... Results from the handler
local function executeServerCallbackHandler(handler, source, ...)
    local success, result = pcall(handler, source, ...)

    if not success then
        amb.print.error('Server callback handler failed for source', source, ':', result)

        return false, nil
    end

    return true, result
end

--- Register a server callback handler
---@param callbackName string The callback identifier
---@param handler function The function to execute when called (receives source as first parameter)
---@return boolean success Whether registration was successful
function amb.registerServerCallback(callbackName, handler)
    print('[DEBUG] registerServerCallback called with:')
    print('[DEBUG]   callbackName:', callbackName)
    print('[DEBUG]   handler type:', type(handler))
    print('[DEBUG]   handler value:', handler)

    -- Accepter les fonctions ET les tables avec __call metamethod
    local handlerType = type(handler)
    local isCallable = handlerType == 'function' or (handlerType == 'table' and getmetatable(handler) and getmetatable(handler).__call)

    print('[DEBUG]   is callable:', isCallable)
    print('[DEBUG]   metatable:', getmetatable(handler))

    if not isCallable then
        amb.print.error('Callback handler must be a function or callable table, got:', type(handler))

        return false
    end

    local resourceName = getResourceContext()
    local success = registerCallbackHandler(callbackName, resourceName)

    if not success then
        return false
    end

    serverCallbacks.handlers[callbackName] = handler
    amb.print.debug('Registered server callback:', callbackName)

    return true
end

--- Trigger a client callback and handle response
---@param callbackName string The callback identifier
---@param playerId number The target player ID
---@param options table|false Options for the call (timeout) or false for defaults
---@param responseHandler function Function to handle the response
---@param ... any Arguments to send to the client callback
function amb.triggerClientCallback(callbackName, playerId, options, responseHandler, ...)
    if type(responseHandler) ~= 'function' then
        amb.print.error('Response handler must be a function for callback:', callbackName)

        return
    end

    local isValid, reason = validatePlayerConnection(playerId)
    if not isValid then
        amb.print.error('Cannot trigger callback for invalid player', playerId, ':', reason)

        return
    end

    if not checkPlayerCallLimit(playerId) then
        return
    end

    local callOptions = {
        timeout = serverCallbacks.config.defaultTimeout
    }

    if options and type(options) == 'table' then
        callOptions.timeout = options.timeout or serverCallbacks.config.defaultTimeout
    end

    local requestId = generateServerRequestId(callbackName, playerId)
    local resourceName = getResourceContext()

    serverCallbacks.pendingRequests[requestId] = {
        callbackName = callbackName,
        playerId = playerId,
        responseHandler = responseHandler,
        createdAt = GetGameTimer()
    }

    TriggerClientEvent('ambitions:callback:validate', playerId, callbackName, resourceName, requestId)
    TriggerClientEvent('ambitions:callback:client:call', playerId, callbackName, resourceName, requestId, ...)

    SetTimeout(callOptions.timeout, function()
        local pendingRequest = serverCallbacks.pendingRequests[requestId]

        if pendingRequest then
            serverCallbacks.pendingRequests[requestId] = nil
            amb.print.warning('Client callback request timed out:', callbackName, 'for player', playerId, 'after', callOptions.timeout, 'ms')
        end
    end)
end

RegisterNetEvent(SERVER_EVENTS.INCOMING_CALL, function(callbackName, requestingResource, requestId, ...)
    local handler = serverCallbacks.handlers[callbackName]
    local playerSource = source

    if not handler then
        amb.print.warning('Received call for unregistered callback:', callbackName, 'from player', playerSource)
        TriggerClientEvent(('ambitions:callback:response:%s'):format(requestingResource), playerSource, requestId, 'callback_not_registered')

        return
    end

    -- Validate source player
    local isValid, reason = validatePlayerConnection(playerSource)

    if not isValid then
        amb.print.warning('Invalid player', playerSource, 'tried to call callback:', callbackName, '- reason:', reason)
        return
    end

    local success, result = executeServerCallbackHandler(handler, playerSource, ...)
    TriggerClientEvent(('ambitions:callback:response:%s'):format(requestingResource), playerSource, requestId, success and result or 'execution_failed')
end)

RegisterNetEvent('ambitions:callback:client:response', function(requestingResource, requestId, ...)
    local pendingRequest = serverCallbacks.pendingRequests[requestId]

    if not pendingRequest then
        amb.print.warning('Received response for unknown request:', requestId)

        return
    end

    serverCallbacks.pendingRequests[requestId] = nil

    local args = {...}
    if args[1] == false and args[2] == 'callback_not_registered' then
        amb.print.error('Client callback not registered:', pendingRequest.callbackName, 'for player', pendingRequest.playerId)

        return
    end

    pendingRequest.responseHandler(...)
end)