local DEFAULT_STREAMING_TIMEOUT <const> = 30000

--- Requests and waits for an asset to be loaded into memory
---@async
---@generic T : string | number
---@param requestFn function Native function to request the asset
---@param isLoadedFn function Native function to check if asset is loaded
---@param assetType string Type of asset for error messages (e.g., 'animDict', 'model')
---@param asset T The asset identifier to load
---@param timeout? number Timeout in milliseconds (default: 30000)
---@param ... any Additional arguments passed to requestFn
---@return T asset The loaded asset identifier
function amb.streaming.request(requestFn, isLoadedFn, assetType, asset, timeout, ...)
    if isLoadedFn(asset) then
        return asset
    end

    requestFn(asset, ...)

    local errorMsg = ('Failed to load %s "%s" - possible causes: too many loaded assets, invalid or corrupted asset'):format(assetType, asset)

    return WaitUntil(function()
        if isLoadedFn(asset) then
            return asset
        end
    end, errorMsg, timeout or DEFAULT_STREAMING_TIMEOUT)
end