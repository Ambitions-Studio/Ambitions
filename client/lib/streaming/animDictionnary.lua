--- Loads an animation dictionary into memory, yielding until loaded when called from a thread
---@param animDict string Animation dictionary name
---@param timeout? number Timeout in milliseconds (default: 10000)
---@return string animDict The loaded animation dictionary name
function amb.streaming.requestAnimDict(animDict, timeout)
    if HasAnimDictLoaded(animDict) then
        return animDict
    end

    if type(animDict) ~= 'string' then
        amb.print.error(('Invalid animDict type: expected string, got %s'):format(type(animDict)))
        return animDict
    end

    if not DoesAnimDictExist(animDict) then
        amb.print.error(('Invalid animDict: %s'):format(animDict))
        return animDict
    end

    return amb.streaming.request(RequestAnimDict, HasAnimDictLoaded, 'animDict', animDict, timeout)
end