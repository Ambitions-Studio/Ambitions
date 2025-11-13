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

    userObject:setIdentifiers(playerIdentifiers)

    local success = amb.cache.addPlayer(sessionId, userObject)

    if not success then 
        amb.print.error('Failed to add player ' .. sessionId .. ' to cache')
        DropPlayer(sessionId, 'Failed to add player ' .. sessionId .. ' to cache, please contant an administrator')
        return
    end
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

    local success = userObject:addCharacter(characterObject)

    if not success then
        amb.print.error('Failed to add character ' .. uniqueId .. ' to user cache for session ' .. sessionId)
        DropPlayer(sessionId, 'Failed to add character ' .. uniqueId .. ' to user cache, please contact an administrator')
        return
    end

    userObject:setCurrentCharacter(uniqueId)
    userObject.currentCharacter:setActive(true)
end)