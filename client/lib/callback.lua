local callbackRegistry = require('shared.lib.callback')
local log = require('shared.lib.log.print')
local ambitionsRandom = require('shared.lib.math.random')

-- Client callback state management
local clientCallbacks = {
    handlers = {},
    pendingRequests = {},
    rateLimiters = {},
    config = {
        defaultTimeout = GetConvarInt('ambitions:callbackTimeout', 3000), -- 3 seconds
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
    local random = ambitionsRandom.alphanumeric(12)

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
        log.warning('Rate limit exceeded for callback:', callbackName)
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
        log.error('Client callback handler failed:', result)

        return false, nil
    end

    return true, result
end

--- Register a client callback handler
---@param callbackName string The callback identifier
---@param handler function The function to execute when called
---@return boolean success Whether registration was successful
local function registerClientCallback(callbackName, handler)
    if type(handler) ~= 'function' then
        log.error('Callback handler must be a function, got:', type(handler))
        return false
    end

    local resourceName = getResourceContext()
    local success = callbackRegistry.register(callbackName, resourceName)

    if not success then
        return false
    end

    clientCallbacks.handlers[callbackName] = handler
    log.debug('Registered client callback:', callbackName)

    return true
end

--- Trigger a server callback and handle response
---@param callbackName string The callback identifier
---@param options table|false Options for the call (delay, timeout) or false for defaults
---@param responseHandler function Function to handle the response
---@param ... any Arguments to send to the server callback
local function triggerServerCallback(callbackName, options, responseHandler, ...)
    if type(responseHandler) ~= 'function' then
        log.error('Response handler must be a function for callback:', callbackName)

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
        log.warning('Maximum concurrent callback limit reached:', activeCalls)

        return
    end

    local requestId = generateRequestId(callbackName)
    local resourceName = getResourceContext()

    clientCallbacks.pendingRequests[requestId] = {
        callbackName = callbackName,
        responseHandler = responseHandler,
        createdAt = GetGameTimer()
    }

    TriggerServerEvent(callbackRegistry.events.VALIDATE, callbackName, resourceName, requestId)
    TriggerServerEvent('ambitions:callback:server:call', callbackName, resourceName, requestId, ...)

    SetTimeout(callOptions.timeout, function()
        local pendingRequest = clientCallbacks.pendingRequests[requestId]

        if pendingRequest then
            clientCallbacks.pendingRequests[requestId] = nil
            log.warning('Callback request timed out:', callbackName, 'after', callOptions.timeout, 'ms')
        end
    end)
end

RegisterNetEvent(CLIENT_EVENTS.INCOMING_CALL, function(callbackName, requestingResource, requestId, ...)
    local handler = clientCallbacks.handlers[callbackName]

    if not handler then
        log.warning('Received call for unregistered callback:', callbackName)
        TriggerServerEvent(CLIENT_EVENTS.RESPONSE, requestingResource, requestId, false, 'callback_not_registered')

        return
    end

    local success, result = executeCallbackHandler(handler, ...)
    TriggerServerEvent(CLIENT_EVENTS.RESPONSE, requestingResource, requestId, success, result)
end)

RegisterNetEvent(('ambitions:callback:response:%s'):format(getResourceContext()), function(requestId, ...)
    local pendingRequest = clientCallbacks.pendingRequests[requestId]

    if not pendingRequest then
        log.warning('Received response for unknown request:', requestId)

        return
    end

    clientCallbacks.pendingRequests[requestId] = nil

    local args = {...}
    if args[1] == 'callback_not_found' then
        log.error('Server callback not found:', pendingRequest.callbackName)

        return
    end

    pendingRequest.responseHandler(...)
end)

local ambitionsCallback = {
    register = registerClientCallback,
    trigger = triggerServerCallback
}

return ambitionsCallback