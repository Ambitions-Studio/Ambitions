local resourceCallbacks = {}

--- Constants for the callback system
local CALLBACK_EVENTS <const> = {
    REGISTER = 'ambitions:callback:register',
    UNREGISTER = 'ambitions:callback:unregister',
    VALIDATE = 'ambitions:callback:validate'
}

--- Get current resource context
---@return string resourceName The current resource name
local function getCurrentResourceContext()
    return GetInvokingResource() or GetCurrentResourceName()
end

--- Initialize callback storage for a resource
---@param resourceName string The resource to initialize
local function initializeResourceCallbacks(resourceName)
    if not resourceCallbacks[resourceName] then
        resourceCallbacks[resourceName] = {
            registered = {},
            createdAt = GetGameTimer()
        }
        amb.print.debug('Initialized callback storage for resource:', resourceName)
    end
end

--- Clean up all callbacks for a stopped resource
---@param stoppedResource string The resource that stopped
local function cleanupResourceCallbacks(stoppedResource)
    if resourceCallbacks[stoppedResource] then
        local callbackCount = 0
        for _ in pairs(resourceCallbacks[stoppedResource].registered) do
            callbackCount = callbackCount + 1
        end

        resourceCallbacks[stoppedResource] = nil
        amb.print.debug('Cleaned up', callbackCount, 'callbacks for stopped resource:', stoppedResource)
    end
end

--- Register a callback handler for validation
---@param callbackName string The callback identifier
---@param resourceName string The owning resource
---@return boolean success Whether registration was successful
function registerCallbackHandler(callbackName, resourceName)
    initializeResourceCallbacks(resourceName)

    for resource, data in pairs(resourceCallbacks) do
        if resource ~= resourceName and data.registered[callbackName] then
            amb.print.error('Callback conflict:', callbackName, 'already registered by', resource)

            return false
        end
    end

    resourceCallbacks[resourceName].registered[callbackName] = {
        registeredAt = GetGameTimer(),
        calls = 0
    }

    amb.print.debug('Registered callback handler:', callbackName, 'for resource:', resourceName)

    return true
end

--- Unregister a callback handler
---@param callbackName string The callback identifier
---@param resourceName string The owning resource
---@return boolean success Whether unregistration was successful
function unregisterCallbackHandler(callbackName, resourceName)
    if resourceCallbacks[resourceName] and resourceCallbacks[resourceName].registered[callbackName] then
        resourceCallbacks[resourceName].registered[callbackName] = nil
        amb.print.debug('Unregistered callback handler:', callbackName, 'from resource:', resourceName)

        return true
    end

    return false
end

--- Validate if a callback exists and is accessible
---@param callbackName string The callback to validate
---@return boolean exists Whether the callback exists
---@return string|nil ownerResource The resource that owns the callback
function validateCallbackExists(callbackName)
    for resource, data in pairs(resourceCallbacks) do
        if data.registered[callbackName] then
            data.registered[callbackName].calls = data.registered[callbackName].calls + 1

            return true, resource
        end
    end

    return false, nil
end

--- Get callback statistics for monitoring
---@return table stats Detailed callback statistics
function getCallbackStatistics()
    local stats = {
        totalResources = 0,
        totalCallbacks = 0,
        resourceBreakdown = {}
    }

    for resource, data in pairs(resourceCallbacks) do
        local resourceStats = {
            callbacks = 0,
            totalCalls = 0,
            oldestCallback = math.huge,
            newestCallback = 0
        }

        for callbackName, callbackData in pairs(data.registered) do
            resourceStats.callbacks = resourceStats.callbacks + 1
            resourceStats.totalCalls = resourceStats.totalCalls + callbackData.calls
            resourceStats.oldestCallback = math.min(resourceStats.oldestCallback, callbackData.registeredAt)
            resourceStats.newestCallback = math.max(resourceStats.newestCallback, callbackData.registeredAt)
        end

        stats.totalResources = stats.totalResources + 1
        stats.totalCallbacks = stats.totalCallbacks + resourceStats.callbacks
        stats.resourceBreakdown[resource] = resourceStats
    end

    return stats
end

-- Event handlers for resource lifecycle
AddEventHandler('onResourceStop', function(resourceName)
    local currentResource = getCurrentResourceContext()

    if currentResource ~= resourceName then
        cleanupResourceCallbacks(resourceName)
    end
end)

-- Network event for callback validation
RegisterNetEvent(CALLBACK_EVENTS.VALIDATE, function(callbackName, requestingResource, validationToken)
    local exists, ownerResource = validateCallbackExists(callbackName)
    local responseEvent = ('ambitions:callback:response:%s'):format(requestingResource)

    if not exists then
        if IsDuplicityVersion() then
            TriggerClientEvent(responseEvent, source, validationToken, 'callback_not_found')
        else
            TriggerServerEvent(responseEvent, validationToken, 'callback_not_found')
        end
    end
end)