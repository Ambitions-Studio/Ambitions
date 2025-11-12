-- Client callback state management
local clientCallbacks = {
    handlers = {},
    pendingRequests = {},
    rateLimiters = {},
    config = {
        defaultTimeout = GetConvarInt('ambitions:callbackTimeout', 3000),
        maxConcurrentCalls = GetConvarInt('ambitions:callbackConcurrency', 50)
    }
}

-- Network event constants
local CLIENT_EVENTS = {
    INCOMING_CALL = 'ambitions:callback:client:call',
    RESPONSE = 'ambitions:callback:client:response'
}

--- Get the current resource context
---@return string resourceName Current resource name
local function getResourceContext()
    return GetCurrentResourceName()
end

--- Generate unique request identifier
---@param callbackName string The callback being called
---@return string requestId Unique request identifier
local function generateRequestId(callbackName)
    local timestamp = GetGameTimer()
    local random = amb.math.randomAlphanumeric(12)

    return ('%s:%d:%s'):format(callbackName, timestamp, random)
end

--- Check rate limiting for callback triggers
---@param callbackName string The callback being triggered
---@param delayMs number|false Optional delay between calls
---@return boolean allowed Whether the call is allowed
local function checkRateLimit(callbackName, delayMs)
    if not delayMs or delayMs <= 0 then
        return true
    end

    local now = GetGameTimer()
    local lastCall = clientCallbacks.rateLimiters[callbackName]

    if lastCall and (now - lastCall) < delayMs then
        amb.print.warning('Rate limit exceeded for callback:', callbackName)
        return false
    end

    clientCallbacks.rateLimiters[callbackName] = now

    return true
end

--- Execute callback handler with error protection
---@param handler function The callback handler function
---@param ... any Arguments to pass to the handler
---@return boolean success Whether execution was successful
---@return any ... Results from the handler
local function executeCallbackHandler(handler, ...)
    local success, result = pcall(handler, ...)

    if not success then
        amb.print.error('Client callback handler failed:', result)

        return false, nil
    end

    return true, result
end

--- Register a client callback handler
---@param callbackName string The callback identifier
---@param handler function The function to execute when called
---@return boolean success Whether registration was successful
function amb.registerClientCallback(callbackName, handler)
    -- Accepter les fonctions ET les tables avec __call metamethod (pour cross-resource)
    local handlerType = type(handler)
    local isCallable = handlerType == 'function' or (handlerType == 'table' and getmetatable(handler) and getmetatable(handler).__call)

    if not isCallable then
        amb.print.error('Callback handler must be a function or callable table, got:', type(handler))
        return false
    end

    local resourceName = getResourceContext()
    local success = registerCallbackHandler(callbackName, resourceName)

    if not success then
        return false
    end

    clientCallbacks.handlers[callbackName] = handler
    storeCallbackHandler(callbackName, handler, 'client')
    amb.print.debug('Registered client callback:', callbackName)

    return true
end

--- Trigger a server callback and handle response
---@param callbackName string The callback identifier
---@param options table|false Options for the call (delay, timeout) or false for defaults
---@param responseHandler function Function to handle the response
---@param ... any Arguments to send to the server callback
function amb.triggerServerCallback(callbackName, options, responseHandler, ...)
    -- Accepter les fonctions ET les tables avec __call metamethod (pour cross-resource)
    local responseHandlerType = type(responseHandler)
    local isCallable = responseHandlerType == 'function' or (responseHandlerType == 'table' and getmetatable(responseHandler) and getmetatable(responseHandler).__call)

    if not isCallable then
        amb.print.error('Response handler must be a function or callable table for callback:', callbackName)

        return
    end

    local callOptions = {
        delay = false,
        timeout = clientCallbacks.config.defaultTimeout
    }

    if options and type(options) == 'table' then
        callOptions.delay = options.delay or false
        callOptions.timeout = options.timeout or clientCallbacks.config.defaultTimeout
    elseif options and type(options) == 'number' then
        callOptions.delay = options
    end

    if not checkRateLimit(callbackName, callOptions.delay) then
        return
    end

    local activeCalls = 0
    for _ in pairs(clientCallbacks.pendingRequests) do
        activeCalls = activeCalls + 1
    end

    if activeCalls >= clientCallbacks.config.maxConcurrentCalls then
        amb.print.warning('Maximum concurrent callback limit reached:', activeCalls)

        return
    end

    local requestId = generateRequestId(callbackName)
    local resourceName = getResourceContext()

    local requestData = {
        callbackName = callbackName,
        responseHandler = responseHandler,
        createdAt = GetGameTimer()
    }

    clientCallbacks.pendingRequests[requestId] = requestData
    storePendingRequest(requestId, requestData, 'client')

    TriggerServerEvent('ambitions:callback:validate', callbackName, resourceName, requestId)
    TriggerServerEvent('ambitions:callback:server:call', callbackName, resourceName, requestId, ...)

    SetTimeout(callOptions.timeout, function()
        local pendingRequest = getPendingRequest(requestId, 'client')

        if pendingRequest then
            removePendingRequest(requestId, 'client')
            clientCallbacks.pendingRequests[requestId] = nil
            amb.print.warning('Callback request timed out:', callbackName, 'after', callOptions.timeout, 'ms')
        end
    end)
end

RegisterNetEvent(CLIENT_EVENTS.INCOMING_CALL, function(callbackName, requestingResource, requestId, ...)
    local handler = getCallbackHandler(callbackName, 'client')

    if not handler then
        amb.print.warning('Received call for unregistered callback:', callbackName)
        TriggerServerEvent(CLIENT_EVENTS.RESPONSE, requestingResource, requestId, false, 'callback_not_registered')

        return
    end

    local success, result = executeCallbackHandler(handler, ...)
    TriggerServerEvent(CLIENT_EVENTS.RESPONSE, requestingResource, requestId, success, result)
end)

RegisterNetEvent(('ambitions:callback:response:%s'):format(getResourceContext()), function(requestId, ...)
    local pendingRequest = getPendingRequest(requestId, 'client')

    if not pendingRequest then
        amb.print.warning('Received response for unknown request:', requestId)

        return
    end

    removePendingRequest(requestId, 'client')
    clientCallbacks.pendingRequests[requestId] = nil

    local args = {...}
    if args[1] == 'callback_not_found' then
        amb.print.error('Server callback not found:', pendingRequest.callbackName)

        return
    end

    pendingRequest.responseHandler(...)
end)