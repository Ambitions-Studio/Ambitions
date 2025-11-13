local SECURITY_CONFIG = {
    ENABLE_ENCRYPTION = true,
    ENABLE_RATE_LIMITING = true,
    ENABLE_SOURCE_VALIDATION = true,
    MAX_CALLS_PER_MINUTE = 60,
    SESSION_TIMEOUT = 300000, -- 5 minutes
    HMAC_SECRET_LENGTH = 32
}

--- Simple XOR encryption for callback data
---@param data string The data to encrypt/decrypt
---@param key string The encryption key
---@return string encrypted The encrypted/decrypted data
local function xorEncrypt(data, key)
    local result = {}
    local keyLen = #key
    
    for i = 1, #data do
        local dataChar = string.byte(data, i)
        local keyChar = string.byte(key, ((i - 1) % keyLen) + 1)
        result[i] = string.char(dataChar ~ keyChar)
    end
    
    return table.concat(result)
end

--- Generate HMAC-like signature for data authenticity
---@param data string The data to sign
---@param secret string The secret key
---@return string signature The generated signature
local function generateSignature(data, secret)
    local combined = data .. secret .. tostring(GetGameTimer())
    local hash = 0
    
    for i = 1, #combined do
        hash = ((hash << 5) - hash + string.byte(combined, i)) & 0xFFFFFFFF
    end
    
    return string.format('%08x', hash)
end

--- Validate signature for data authenticity
---@param data string The original data
---@param signature string The signature to validate
---@param secret string The secret key
---@param tolerance number Time tolerance in ms for signature validation
---@return boolean valid Whether the signature is valid
local function validateSignature(data, signature, secret, tolerance)
    tolerance = tolerance or 30000 -- 30 seconds tolerance
    local currentTime = GetGameTimer()
    
    -- Check signatures within tolerance window
    for timeOffset = 0, tolerance, 1000 do
        for direction = -1, 1, 2 do
            local testTime = currentTime + (direction * timeOffset)
            local combined = data .. secret .. tostring(testTime)
            local hash = 0
            
            for i = 1, #combined do
                hash = ((hash << 5) - hash + string.byte(combined, i)) & 0xFFFFFFFF
            end
            
            local testSignature = string.format('%08x', hash)
            if testSignature == signature then
                return true
            end
        end
    end
    
    return false
end

local callbackSecurity = {}
local rateLimitData = {}
local sessionKeys = {}
local trustedSources = {}

--- Initialize security for a resource
---@param resourceName string The resource name to initialize security for
---@return table securityContext The security context for the resource
function callbackSecurity.initializeResource(resourceName)
    if not sessionKeys[resourceName] then
        sessionKeys[resourceName] = amb.math.randomAlphanumeric(SECURITY_CONFIG.HMAC_SECRET_LENGTH)
        trustedSources[resourceName] = {}
        
        amb.print.debug('Initialized security for resource:', resourceName)
        
        -- Cleanup after session timeout
        SetTimeout(SECURITY_CONFIG.SESSION_TIMEOUT, function()
            sessionKeys[resourceName] = nil
            trustedSources[resourceName] = nil
            amb.print.debug('Security session expired for resource:', resourceName)
        end)
    end
    
    return {
        encrypt = function(data)
            if not SECURITY_CONFIG.ENABLE_ENCRYPTION then return data end
            return xorEncrypt(tostring(data), sessionKeys[resourceName])
        end,
        decrypt = function(encryptedData)
            if not SECURITY_CONFIG.ENABLE_ENCRYPTION then return encryptedData end
            return xorEncrypt(encryptedData, sessionKeys[resourceName])
        end,
        sign = function(data)
            return generateSignature(tostring(data), sessionKeys[resourceName])
        end,
        verify = function(data, signature)
            return validateSignature(tostring(data), signature, sessionKeys[resourceName])
        end
    }
end

--- Register a trusted source for callback validation
---@param resourceName string The resource name
---@param source number|string The source to trust (player ID or 'server')
---@param permissions table Optional permissions for this source
function callbackSecurity.registerTrustedSource(resourceName, source, permissions)
    if not SECURITY_CONFIG.ENABLE_SOURCE_VALIDATION then return end
    
    if not trustedSources[resourceName] then
        trustedSources[resourceName] = {}
    end
    
    trustedSources[resourceName][tostring(source)] = {
        registered = GetGameTimer(),
        permissions = permissions or {},
        callCount = 0,
        lastCall = 0
    }
    
    amb.print.debug('Registered trusted source', source, 'for resource', resourceName)
end

--- Validate if a source is trusted and within rate limits
---@param resourceName string The resource name
---@param source number|string The source to validate
---@param callbackName string The callback being called
---@return boolean valid Whether the source is valid
---@return string reason Reason for validation failure (if any)
function callbackSecurity.validateSource(resourceName, source, callbackName)
    if not SECURITY_CONFIG.ENABLE_SOURCE_VALIDATION then
        return true, 'source_validation_disabled'
    end
    
    local sourceStr = tostring(source)
    local trustedResource = trustedSources[resourceName]
    
    if not trustedResource or not trustedResource[sourceStr] then
        amb.print.warning('Untrusted source', source, 'attempted callback', callbackName, 'on resource', resourceName)
        return false, 'untrusted_source'
    end
    
    local sourceData = trustedResource[sourceStr]
    local currentTime = GetGameTimer()
    
    -- Rate limiting
    if SECURITY_CONFIG.ENABLE_RATE_LIMITING then
        local timeSinceLastCall = currentTime - sourceData.lastCall
        
        if timeSinceLastCall < (60000 / SECURITY_CONFIG.MAX_CALLS_PER_MINUTE) then
            amb.print.warning('Rate limit exceeded for source', source, 'on callback', callbackName)
            return false, 'rate_limit_exceeded'
        end
        
        sourceData.callCount = sourceData.callCount + 1
        sourceData.lastCall = currentTime
        
        -- Reset call count every minute
        if not rateLimitData[sourceStr] then
            rateLimitData[sourceStr] = currentTime
            SetTimeout(60000, function()
                if trustedResource[sourceStr] then
                    trustedResource[sourceStr].callCount = 0
                end
                rateLimitData[sourceStr] = nil
            end)
        end
    end
    
    return true, 'valid'
end

--- Create a secure callback key with encryption and signature
---@param resourceName string The resource name
---@param callbackName string The callback name
---@param additionalData string Optional additional data to include
---@return string secureKey The secure callback key
function callbackSecurity.createSecureKey(resourceName, callbackName, additionalData)
    local security = callbackSecurity.initializeResource(resourceName)
    local timestamp = tostring(GetGameTimer())
    local nonce = amb.math.randomAlphanumeric(16)
    local rawData = callbackName .. ':' .. timestamp .. ':' .. nonce
    
    if additionalData then
        rawData = rawData .. ':' .. tostring(additionalData)
    end
    
    local encryptedData = security.encrypt(rawData)
    local signature = security.sign(encryptedData)
    
    -- Encode to make it URL-safe and readable
    local secureKey = amb.math.randomAlphanumeric(4) .. '_' .. 
                      string.gsub(encryptedData, '[^%w]', function(c)
                          return string.format('%%%02X', string.byte(c))
                      end) .. '_' .. signature
    
    return secureKey
end

--- Validate and decrypt a secure callback key
---@param resourceName string The resource name
---@param secureKey string The secure key to validate
---@return boolean valid Whether the key is valid
---@return table|nil data The decrypted data if valid
function callbackSecurity.validateSecureKey(resourceName, secureKey)
    local security = callbackSecurity.initializeResource(resourceName)
    
    -- Parse the secure key format: prefix_encryptedData_signature
    local parts = {}
    for part in string.gmatch(secureKey, '([^_]+)') do
        table.insert(parts, part)
    end
    
    if #parts ~= 3 then
        return false, nil
    end
    
    local encryptedData = string.gsub(parts[2], '%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
    end)
    local signature = parts[3]
    
    -- Validate signature
    if not security.verify(encryptedData, signature) then
        amb.print.warning('Invalid signature for callback key from resource', resourceName)
        return false, nil
    end
    
    -- Decrypt and parse data
    local rawData = security.decrypt(encryptedData)
    local dataParts = {}
    for part in string.gmatch(rawData, '([^:]+)') do
        table.insert(dataParts, part)
    end
    
    if #dataParts < 3 then
        return false, nil
    end
    
    local data = {
        callbackName = dataParts[1],
        timestamp = tonumber(dataParts[2]),
        nonce = dataParts[3],
        additionalData = dataParts[4]
    }
    
    -- Validate timestamp (prevent replay attacks)
    local currentTime = GetGameTimer()
    if math.abs(currentTime - data.timestamp) > 30000 then -- 30 second tolerance
        amb.print.warning('Callback key timestamp too old or invalid for resource', resourceName)
        return false, nil
    end
    
    return true, data
end

--- Get security statistics for monitoring
---@param resourceName string The resource name
---@return table stats Security statistics
function callbackSecurity.getSecurityStats(resourceName)
    local stats = {
        encryption_enabled = SECURITY_CONFIG.ENABLE_ENCRYPTION,
        rate_limiting_enabled = SECURITY_CONFIG.ENABLE_RATE_LIMITING,
        source_validation_enabled = SECURITY_CONFIG.ENABLE_SOURCE_VALIDATION,
        session_active = sessionKeys[resourceName] ~= nil,
        trusted_sources = 0,
        total_calls = 0
    }
    
    if trustedSources[resourceName] then
        for source, data in pairs(trustedSources[resourceName]) do
            stats.trusted_sources = stats.trusted_sources + 1
            stats.total_calls = stats.total_calls + data.callCount
        end
    end
    
    return stats
end

--- Clean up security data for a resource
---@param resourceName string The resource name to clean up
function callbackSecurity.cleanupResource(resourceName)
    sessionKeys[resourceName] = nil
    trustedSources[resourceName] = nil
    amb.print.debug('Cleaned up security data for resource:', resourceName)
end

return callbackSecurity