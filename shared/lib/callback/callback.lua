--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

amb.registeredCallbacks = amb.registeredCallbacks or {}
local registeredCallbacks = amb.registeredCallbacks

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then return end

    for callbackName, resource in pairs(registeredCallbacks) do
        if resource == resourceName then
            registeredCallbacks[callbackName] = nil
        end
    end
end)

---For internal use only.
---Sets a callback event as registered to a specific resource, preventing it from
---being overwritten. Any unknown callbacks will return an error to the caller.
---@param callbackName string
---@param isValid boolean
function SetValidCallback(callbackName, isValid)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    local callbackResource = registeredCallbacks[callbackName]

    if callbackResource then
        if not isValid then
            callbackResource[callbackName] = nil
            return
        end

        if callbackResource == resourceName then return end

        local errMessage = ("^1resource '%s' attempted to overwrite callback '%s' owned by resource '%s'^0"):format(resourceName, callbackName, callbackResource)

        return amb.print.error(('%s^0\n%s'):format(errMessage, Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
    end

    amb.print.debug(("set valid callback '%s' for resource '%s'"):format(callbackName, resourceName))

    registeredCallbacks[callbackName] = resourceName
end

--- Checks if a callback is registered by the invoking resource
---@param callbackName string The name of the callback to check
---@return boolean isValid Whether the callback is valid for this resource
function IsCallbackValid(callbackName)
    return registeredCallbacks[callbackName] == GetInvokingResource() or GetCurrentResourceName()
end

local cbEvent = '__ambitions_callback_%s'

RegisterNetEvent('ambitions:validateCallback', function(callbackName, invokingResource, key)
    if registeredCallbacks[callbackName] then return end

    local event = cbEvent:format(invokingResource)

    if GetGameName() == 'fxserver' then
        return TriggerClientEvent(event, source, key, 'cb_invalid')
    end

    TriggerServerEvent(event, key, 'cb_invalid')
end)
