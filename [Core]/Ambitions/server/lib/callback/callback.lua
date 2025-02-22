--- Credits: https://github.com/overextended/ox_lib

local pendingCallbacks = {}
local cbEvent = '__ambitions_callback_%s'
local callbackTimeout = GetConvarInt('ambitions:callbackTimeout', 300000)

RegisterNetEvent(cbEvent:format(GetCurrentResourceName()), function(key, ...)
    local cb = pendingCallbacks[key]
    pendingCallbacks[key] = nil

---@diagnostic disable-next-line: redundant-return-value
    return cb and cb(...)
end)

---@param _ any
---@param event string
---@param playerId number
---@param cb function|false
---@param ... any
---@return ...
local function triggerClientCallback(_, event, playerId, cb, ...)
    assert(DoesPlayerExist(playerId --[[@as string]]), ("target playerId '%s' does not exist"):format(playerId))

    local key

    repeat
        key = ('%s:%s:%s'):format(event, math.random(0, 100000), playerId)
    until not pendingCallbacks[key]

    TriggerClientEvent(cbEvent:format(event), playerId, GetCurrentResourceName(), key, ...)

    ---@type promise | false
    local promise = not cb and promise.new()

    pendingCallbacks[key] = function(response, ...)
        response = { response, ... }

        if promise then
            return promise:resolve(response)
        end

        if cb then
            cb(table.unpack(response))
        end
    end

    if promise then
        SetTimeout(callbackTimeout, function() promise:reject(("callback event '%s' timed out"):format(key)) end)

        return table.unpack(Citizen.Await(promise))
    end
end

---@overload fun(event: string, playerId: number, cb: function, ...)
ABT.Callback = setmetatable({}, {
    __call = function(_, event, playerId, cb, ...)
        if not cb then
            warn(("callback event '%s' does not have a function to callback to and will instead await\nuse ABT.callback.await or a regular event to remove this warning")
                :format(event))
        else
            local cbType = type(cb)

            assert(cbType == 'function', ("expected argument 3 to have type 'function' (received %s)"):format(cbType))
        end

        return triggerClientCallback(_, event, playerId, cb, ...)
    end
})

---@param event string
---@param playerId number
--- Sends an event to a client and halts the current thread until a response is returned.
---@diagnostic disable-next-line: duplicate-set-field
function ABT.Callback.await(event, playerId, ...)
    return triggerClientCallback(nil, event, playerId, false, ...)
end

local function callbackResponse(success, result, ...)
    if not success then
        if result then
            return ABT.Print.Log(3, ( '%s^0\n%s'):format(result,
                Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
        end

        return false
    end

    return result, ...
end

local pcall = pcall

---@param name string
---@param cb function
---Registers an event handler and callback function to respond to client requests.
---@diagnostic disable-next-line: duplicate-set-field
function ABT.Callback.Register(name, cb)
    RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
        TriggerClientEvent(cbEvent:format(resource), source, key, callbackResponse(pcall(cb, source, ...)))
    end)
end

return ABT.Callback