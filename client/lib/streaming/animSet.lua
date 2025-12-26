--- Loads an animation clipset into memory, yielding until loaded when called from a thread
---@param animSet string Animation clipset name
---@param timeout? number Timeout in milliseconds (default: 10000)
---@return string animSet The loaded animation clipset name
function amb.streaming.requestAnimSet(animSet, timeout)
    if HasAnimSetLoaded(animSet) then
        return animSet
    end

    if type(animSet) ~= 'string' then
        amb.print.error(('Invalid animSet type: expected string, got %s'):format(type(animSet)))
        return animSet
    end

    return amb.streaming.request(RequestAnimSet, HasAnimSetLoaded, 'animSet', animSet, timeout)
end