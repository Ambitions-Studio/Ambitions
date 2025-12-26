--- Loads a particle effect asset into memory, yielding until loaded when called from a thread
---@param ptfxName string Particle effect asset name
---@param timeout? number Timeout in milliseconds (default: 10000)
---@return string ptfxName The loaded particle effect asset name
function amb.streaming.requestPtfxAsset(ptfxName, timeout)
    if HasNamedPtfxAssetLoaded(ptfxName) then
        return ptfxName
    end

    if type(ptfxName) ~= 'string' then
        amb.print.error(('Invalid ptfxName type: expected string, got %s'):format(type(ptfxName)))
        return ptfxName
    end

    return amb.streaming.request(RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, 'ptfxAsset', ptfxName, timeout)
end