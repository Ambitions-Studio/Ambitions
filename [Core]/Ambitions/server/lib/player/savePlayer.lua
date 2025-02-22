local debug = import('config.shared.config_debug')

--- Save player data to the database
---@param source number The player's server ID
---@param callback function The function to call after the player data is saved
---@return boolean Whether the player data was saved successfully
---@return void
function ABT.Player.SavePlayer(source, callback)
    local player = ABT.GetPlayerFromId(source)
    ABT.Print.Log(2, 'player :', player)
    local character = player.getCurrentCharacter()
    ABT.Print.Log(2, 'character :', character)
    local PLAYER_LICENSE <const> = player.license:match("^license:(.+)$")
    ABT.Print.Log(2, 'player license :', PLAYER_LICENSE)

    if not PLAYER_LICENSE then
        ABT.Print.Log(3, 'Failed to retreive license for source :', source)

        if callback then callback(false) end
        return
    end

    local ped = GetPlayerPed(source)
    local pedPositions = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)
    local queryCharacterParameters = {
        characterModel = character.getCharacterModel(),
        characterNeeds = json.encode(character.needs.getAllNeeds()),
        characterPoition = {
            x = ABT.Math.Round(pedPositions.x, 4),
            y = ABT.Math.Round(pedPositions.y, 4),
            z = ABT.Math.Round(pedPositions.z, 4),
            h = ABT.Math.Round(pedHeading, 4)
        },
        characterGroup = character.getGroup(),
        characerIsDead = character.getDeathState(),
        characterStatus = json.encode(character.getStatus())
    }

    local queryUserId = [[
        SELECT characters.id AS character_id, characters.unique_id
        FROM characters
        INNER JOIN users ON characters.user_id = users.id
        WHERE users.license = ?
    ]]

    MySQL.Async.fetchAll(queryUserId, {PLAYER_LICENSE}, function(result)
        if not result then
            ABT.Print.Log(3, 'Failed to retreive and save character data for player license :', PLAYER_LICENSE)

            if callback then callback(false) end
            return
        end

        -- if debug.Save.DebugSavePlayer then
        --     ABT.Print.Log(5, 'Character data query result:', result)
        -- end

        local characterUniqueId = result[1].unique_id
        local characterId = result[1].character_id

        local characterAccounts = character.accounts.getAllAccounts()
        local updateCharacterAccountQuery = [[
            UPDATE characters_accounts
            SET account_amount = ?, account_metadata = ?
            WHERE character_id = ? AND account_type = ?
        ]]

        ABT.Print.Log(5, 'characterAccounts :', characterAccounts)
        for accountType, accountData in pairs(characterAccounts) do
            MySQL.Async.execute(updateCharacterAccountQuery, {accountData.balance, json.encode(accountData.metadata), characterId, accountType}, function(affectedRows)
                if affectedRows == 0 then
                    ABT.Print.Log(3, 'Failed to update / save account for source :', SOURCE)

                    if callback then callback(false) end
                    return
                end

                -- if debug.Save.DebugSavePlayer then
                --     ABT.Print.Log(5, ('Account updated for type "%s": %d rows affected.'):format(accountType, rowsAffected))
                -- end
            end)
        end

        -- if debug.Save.DebugSavePlayer then
        --     ABT.Print.Log(5, 'Unique ID query result:', uniqueID)
        -- end

        local updateCharacterQuery = [[
            UPDATE characters
            SET
                `group` = ?,
                needs = ?,
                ped_model = ?,
                position_x = ?,
                position_y = ?,
                position_z = ?,
                heading = ?,
                `status` = ?,
                isDead = ?,
                last_played = CURRENT_TIMESTAMP
            WHERE unique_id = ?
        ]]

        local updateCharacterParams = {
            queryCharacterParameters.characterGroup,
            queryCharacterParameters.characterNeeds,
            queryCharacterParameters.characterModel,
            queryCharacterParameters.characterPoition.x,
            queryCharacterParameters.characterPoition.y,
            queryCharacterParameters.characterPoition.z,
            queryCharacterParameters.characterPoition.h,
            queryCharacterParameters.characterStatus,
            queryCharacterParameters.characerIsDead,
            characterUniqueId
        }

        MySQL.Async.execute(updateCharacterQuery, updateCharacterParams, function(affectedRows)
            if affectedRows == 0 then
                ABT.Print.Log(3, 'Faild to update / save character data white unique id :', characterUniqueId, 'and source :', SOURCE)

                if callback then callback(false) end
                return
            end

            local characterJob = character.getJob()
            local characterCrew = character.getCrew()
            local updateCharacterJobQuery = [[
                UPDATE character_affiliations
                SET job = ?, job_grade = ?, on_duty_job = ?, crew = ?, crew_grade = ?, on_duty_crew = ?
                WHERE character_id = ?
            ]]

            local updateCharacterJobParams = {
                characterJob.name,
                characterJob.gradeName,
                characterJob.on_duty_job and 1 or 0,
                characterCrew.name,
                characterCrew.gradeName,
                characterCrew.on_duty_crew and 1 or 0,
                characterId
            }

            MySQL.Async.execute(updateCharacterJobQuery, updateCharacterJobParams)

            local updateCharacterLicenseQuery = [[
                INSERT INTO character_licenses (character_unique_id, license_type, license_status, license_metadata)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    license_status = VALUES(license_status),
                    license_metadata = VALUES(license_metadata)
            ]]

            local characterLicenses = character.getAllLicenses()

            if characterLicenses and next(characterLicenses) then
                for licenseType, licenseData in pairs(characterLicenses) do
                    if licenseType and type(licenseData) == "table" then
                        MySQL.Async.execute(updateCharacterLicenseQuery, { character.getUniqueID(), licenseType, licenseData.status and 1 or 0, json.encode(licenseData.metadata), }, function(affectedLicenses)
                            if affectedLicenses > 0 then
                                ABT.Print.Log(5, ("License '%s' saved for player '%s'."):format(licenseType, character.getUniqueID()))
                            else
                                ABT.Print.Log(3, ("Failed to save license '%s' for player '%s'."):format(licenseType, character.getUniqueID()))
                            end
                        end)
                    else
                        ABT.Print.Log(3, ("Invalid license data for license type '%s' for player '%s'."):format(licenseType, character.getUniqueID()))
                    end
                end
            else
                ABT.Print.Log(3, ("No licenses found for player '%s'."):format(character.getUniqueID()))
            end


            -- if debug.Save.DebugSavePlayer then
            --     ABT.Print.Log(5, 'Character data updated for unique_id:', uniqueID)
            -- end

            local updateUserQuery = [[
                UPDATE users
                SET last_login = CURRENT_TIMESTAMP
                WHERE license = ?
            ]]

            MySQL.Async.execute(updateUserQuery, {PLAYER_LICENSE}, function(affectedRows)
                if affectedRows == 0 then
                    ABT.Print.Log(3, 'Failed to update / save user data for license :', PLAYER_LICENSE, ' And source :', SOURCE)

                    if callback then callback(false) end
                    return
                end

                -- if debug.Save.DebugSavePlayer then
                --     ABT.Print.Log(5, 'User data updated for license:', playerLicense)
                -- end

                if callback then callback(true) end
            end)
        end)
    end)
end

return ABT.Player.SavePlayer