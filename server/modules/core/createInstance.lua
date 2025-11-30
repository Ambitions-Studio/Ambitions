RegisterNetEvent('ambitions:server:insertUserIntoCache', function(sessionId, playerLicense)

    if not sessionId or not playerLicense then
        amb.print.error('Missing sessionid or player license to inser user into cache')
        DropPlayer(sessionId, 'Missing sessionid or player license to insert user into cache, please contact an administrator')
        return
    end

    local playerIdentifiers = amb.getPlayerIdentifers(sessionId)
    if not playerIdentifiers or not playerIdentifiers.license then
        amb.print.error('Failed to get player identifers for session id ' .. sessionId)
        DropPlayer(sessionId, 'Failed to get player identifers for session id ' .. sessionId .. ', please contact an administrator')
        return
    end

    local userObject = CreateAmbitionsUserObject(sessionId, playerLicense)

    if not userObject then
        amb.print.error('Failed to create an instance of the user for the player '.. sessionId)
        DropPlayer(sessionId, 'Failed to create an instance of the user for the player '.. sessionId .. ', please contact an administrator')
        return
    end

    userObject.setIdentifiers(playerIdentifiers)

    local success = amb.cache.addPlayer(sessionId, userObject)

    if not success then
        amb.print.error('Failed to add player ' .. sessionId .. ' to cache')
        DropPlayer(sessionId, 'Failed to add player ' .. sessionId .. ' to cache, please contant an administrator')
        return
    end

    -- Debug prints
    amb.print.success('User inserted into cache for session ' .. sessionId)
    amb.print.info('User Object:')
    amb.print.info(userObject)
    amb.print.info('Cache Stats:')
    amb.print.info(amb.cache.getPlayerCacheStats())
end)



RegisterNetEvent('ambitions:server:insertCharacterIntoCache', function(sessionId, uniqueId, characterData)

    if not sessionId or not uniqueId or not characterData then
        amb.print.error('Missing sessionId, uniqueId or characterData to insert character into cache')
        DropPlayer(sessionId, 'Missing sessionId, uniqueId or characterData to insert character into cache, please contact an administrator')
        return
    end

    local userObject = amb.cache.getPlayer(sessionId)

    if not userObject then
        amb.print.error('Failed to get user from cache for session ' .. sessionId)
        DropPlayer(sessionId, 'Failed to get user from cache for session ' .. sessionId .. ', please contact an administrator')
        return
    end

    local characterObject = CreateAmbitionsCharacterObject(sessionId, uniqueId, characterData)

    if not characterObject then
        amb.print.error('Failed to create character object for uniqueId ' .. uniqueId)
        DropPlayer(sessionId, 'Failed to create character object for uniqueId ' .. uniqueId .. ', please contact an administrator')
        return
    end

    local success = userObject.addCharacter(characterObject)

    if not success then
        amb.print.error('Failed to add character ' .. uniqueId .. ' to user cache for session ' .. sessionId)
        DropPlayer(sessionId, 'Failed to add character ' .. uniqueId .. ' to user cache, please contact an administrator')
        return
    end

    userObject.setCurrentCharacter(uniqueId)
    userObject.currentCharacter.setActive(true)

    -- Debug prints
    amb.print.success('Character inserted into cache for session ' .. sessionId .. ' with uniqueId ' .. uniqueId)
    amb.print.info('User Object:')
    amb.print.info(userObject)
    amb.print.info('Character Object:')
    amb.print.info(characterObject)
    amb.print.info('Cache Stats:')
    amb.print.info(amb.cache.getPlayerCacheStats())
end)

RegisterNetEvent('ambitions:server:insertRetrievedIntoCache', function(sessionId, playerLicense, characters)

    if not sessionId or not playerLicense then
        amb.print.error('Missing sessionId or playerLicense to insert retrieved user into cache')
        DropPlayer(sessionId, 'Missing sessionId or playerLicense to insert retrieved user into cache, please contact an administrator')
        return
    end

    -- Step 1: Insert User into cache
    local playerIdentifiers = amb.getPlayerIdentifers(sessionId)
    if not playerIdentifiers or not playerIdentifiers.license then
        amb.print.error('Failed to get player identifiers for session id ' .. sessionId)
        DropPlayer(sessionId, 'Failed to get player identifiers for session id ' .. sessionId .. ', please contact an administrator')
        return
    end

    local userObject = CreateAmbitionsUserObject(sessionId, playerLicense)

    if not userObject then
        amb.print.error('Failed to create an instance of the user for the player '.. sessionId)
        DropPlayer(sessionId, 'Failed to create an instance of the user for the player '.. sessionId .. ', please contact an administrator')
        return
    end

    userObject.setIdentifiers(playerIdentifiers)

    local success = amb.cache.addPlayer(sessionId, userObject)

    if not success then
        amb.print.error('Failed to add player ' .. sessionId .. ' to cache')
        DropPlayer(sessionId, 'Failed to add player ' .. sessionId .. ' to cache, please contact an administrator')
        return
    end

    amb.print.success('User inserted into cache for session ' .. sessionId)

    -- Step 2: Insert all Characters into cache (without setting as current)
    if not characters or #characters == 0 then
        amb.print.error('No characters to load for session ' .. sessionId)
        return
    end

    for i = 1, #characters do
        local char = characters[i]

        local needsData = nil
        if char.needs then
            local success, decoded = pcall(json.decode, char.needs)
            if success then
                needsData = decoded
            end
        end

        local statusData = nil
        if char.status then
            local statusSuccess, statusDecoded = pcall(json.decode, char.status)
            if statusSuccess then
                statusData = statusDecoded
            end
        end

        local characterData = {
            firstname = char.firstname,
            lastname = char.lastname,
            dateofbirth = char.dateofbirth,
            sex = char.sex,
            nationality = char.nationality,
            height = char.height,
            appearance = char.appearance,
            pedModel = char.ped_model,
            position = {
                x = char.position_x,
                y = char.position_y,
                z = char.position_z,
                heading = char.heading
            },
            group = char.group or 'user',
            playtime = char.playtime or 0,
            createdAt = char.created_at,
            lastPlayed = char.last_played,
            needs = needsData,
            isDead = char.is_dead == 1,
            status = statusData
        }

        local characterObject = CreateAmbitionsCharacterObject(sessionId, char.unique_id, characterData)

        if not characterObject then
            amb.print.error('Failed to create character object for uniqueId ' .. char.unique_id)
        else
            local addSuccess = userObject.addCharacter(characterObject)

            if not addSuccess then
                amb.print.error('Failed to add character ' .. char.unique_id .. ' to user cache for session ' .. sessionId)
            else
                amb.print.success('Character ' .. char.unique_id .. ' added to cache for session ' .. sessionId)
            end
        end
    end

    -- Debug prints
    amb.print.success('All characters loaded into cache for session ' .. sessionId)
    amb.print.info('User Object:')
    amb.print.info(userObject)
    amb.print.info('Total characters loaded: ' .. userObject.getCharacterCount())
    amb.print.info('Cache Stats:')
    amb.print.info(amb.cache.getPlayerCacheStats())
end)