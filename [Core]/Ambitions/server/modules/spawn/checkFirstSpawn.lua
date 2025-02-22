local debug = import('config.shared.config_debug')
local spawn = import('config.shared.config_spawn')

--- Check if the unique ID is already in use.
---@param uniqueID string The unique ID to check.
---@return boolean Whether the unique ID is in use.
local function IsUniqueIDInUse(uniqueID)
    local p = promise.new()

    MySQL.Async.fetchScalar("SELECT 1 FROM characters WHERE unique_id = ?", {uniqueID}, function(result)
        p:resolve(result ~= nil)
    end)

    return Citizen.Await(p)
end

--- Generate a unique ID for the character.
--- @return string uniqueID The unique ID generated.
local function GenerateUniqueID()
    local CHARSET <const> = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local LENGTH <const> = 5
    local uniqueID = ''

    for _ = 1, LENGTH do
        local RAND <const> = math.random(1, #CHARSET )
        uniqueID = uniqueID .. CHARSET:sub(RAND, RAND)
    end

    return uniqueID
end

--- Get a valid random unique ID.
--- @return string uniqueID The unique ID generated and checked.
local function GetValidUniqueID()
    local uniqueID

    repeat
        uniqueID = GenerateUniqueID()
    until not IsUniqueIDInUse(uniqueID)

    return uniqueID
end

--- Insert the default account for the character in the database.
---@param characterId number The character's ID in the database.
local function InsertDefaultAccount(characterId)
    for accountType, startingAmount in pairs(spawn.STARTING_ACCOUNT_MONEY) do
        local insertionQuery = [[
            INSERT INTO characters_accounts (character_id, account_type, account_amount)
            VALUES (?, ?, ?)
        ]]

        MySQL.Async.execute(insertionQuery, {characterId, accountType, startingAmount})
    end
end

--- Insert the character with default accounts and job in the database.
---@param source number The player's server ID.
---@param userID number The user's ID in the database.
---@param amberPlayer table The player's Amber object.
local function InsertOrFetchCharacter(source, userID, amberPlayer)
    local characterData = {
        unique_id = GetValidUniqueID(),
        group = 'user',
        needs = '{}',
        ped_model = spawn.DEFAULT_MODEL,
        position_x = spawn.DEFAULT_SPAWN_POSITION.x,
        position_y = spawn.DEFAULT_SPAWN_POSITION.y,
        position_z = spawn.DEFAULT_SPAWN_POSITION.z,
        heading = spawn.DEFAULT_SPAWN_POSITION.w,
        status = {
            health = 200,
            armor = 0
        },
        isDead = 0,
    }

    local characterQuery = [[
        INSERT INTO characters (user_id, unique_id, `group`, `needs`, ped_model, position_x, position_y, position_z, heading, `status`, isDead)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE last_played = CURRENT_TIMESTAMP
    ]]

    local insertJobQuery = [[
        INSERT INTO character_affiliations (character_id, job, job_grade, on_duty_job, crew, crew_grade, on_duty_crew)
        VALUES (?, 'unemployed', 'unemployed', 0, 'none', 'none', 0)
        ON DUPLICATE KEY UPDATE job = VALUES(job), job_grade = VALUES(job_grade), on_duty_job = VALUES(on_duty_job),
                                 crew = VALUES(crew), crew_grade = VALUES(crew_grade), on_duty_crew = VALUES(on_duty_crew)
    ]]

    local retrieveJobQuery = [[
        SELECT job, job_grade, on_duty_job, crew, crew_grade, on_duty_crew
        FROM character_affiliations
        WHERE character_id = ?
    ]]

    MySQL.Async.execute(characterQuery, { userID, characterData.unique_id, characterData.group, characterData.needs, characterData.ped_model, characterData.position_x, characterData.position_y, characterData.position_z, characterData.heading, json.encode(characterData.status), characterData.isDead, }, function()
        if debug.Spawn.DebugCharacter then
            ABT.Print.Log(5, rowsAffected .. " rows affected. Character inserted for user ID:", userID)
        end

        MySQL.Async.fetchScalar('SELECT id FROM characters WHERE user_id = ?', { userID }, function(characterID)
            if not characterID then
                if debug.Spawn.DebugCharacter then
                    ABT.Print.Log(3, 'Failed to retrieve character ID for user ID:', userID)
                end

                DropPlayer(source, 'Failed to retrieve your character ID. Please contact support.')
            end

            if debug.Spawn.DebugCharacter then
                ABT.Print.Log(5, 'Character ID:', characterID)
            end

            InsertDefaultAccount(characterID)
            local getAccountsInfoQuery = 'SELECT account_type, account_amount, account_metadata FROM characters_accounts WHERE character_id = ?'
            MySQL.Async.fetchAll(getAccountsInfoQuery, {characterID}, function(accountsInfo)
                if debug.Spawn.DebugAccounts then
                    ABT.Print.Log(5, 'Accounts Info:', accountsInfo)
                end

                local accounts = {}

                for _, accountInfo in ipairs(accountsInfo) do
                    accounts[accountInfo.account_type] = {
                        balance = accountInfo.account_amount,
                        metadata = json.decode(accountInfo.account_metadata)
                    }
                end

                if debug.Spawn.DebugAccounts then
                    ABT.Print.Log(5, 'Accounts:', accounts)
                end

                MySQL.Async.execute(insertJobQuery, { characterID })
                MySQL.Async.fetchAll(retrieveJobQuery, { characterID}, function(jobResult)
                    local characterAffiliation = {}

                    ABT.Print.Log(5, 'Job Result:', jobResult)

                    for _, row in ipairs(jobResult) do
                        if not ABT.DoesSocietyExist(row.job, row.job_grade) then
                            ABT.Print.Log(3, 'The job does not exist:', row.job, row.job_grade, '. So ignoring it.')
                            row.job = 'unemployed'
                            row.job_grade = 'unemployed'
                            row.on_duty_job = 0
                        end

                        if not ABT.DoesCrewExist(row.crew, row.crew_grade) then
                            ABT.Print.Log(3, 'The crew does not exist:', row.crew, row.crew_grade, '. So ignoring it.')
                            row.crew = 'none'
                            row.crew_grade = 'none'
                            row.on_duty_crew = 0
                        end

                        local jobObject = ABT.Societies[row.job]
                        local jobGradeObject = jobObject and jobObject.societyGrades.getGrade(row.job_grade) or nil
                        local crewObject = ABT.Crews[row.crew]
                        local crewGradeObject = crewObject and crewObject.crewGrades.getGrade(row.crew_grade) or nil

                        characterAffiliation = {
                            job = row.job,
                            job_grade = row.job_grade,
                            on_duty_job = row.on_duty_job,
                            crew = row.crew,
                            crew_grade = row.crew_grade,
                            on_duty_crew = row.on_duty_crew,
                        }

                        characterData.job = {
                            name = jobObject.societyName,
                            label = jobObject.societyLabel,
                            isOwner = (jobObject.societyOwner == amberPlayer.license),

                            gradeRank = jobGradeObject.rank,
                            gradeName = jobGradeObject.name,
                            gradeLabel = jobGradeObject.label,
                            gradeSalary = jobGradeObject.salary,
                            gradePermissions = jobGradeObject.permission,
                            gradeWhitelisted = jobGradeObject.whitelisted,
                        }

                        characterData.crew = {
                            name = crewObject.crewName,
                            label = crewObject.crewLabel,
                            isOwner = (crewObject.crewOwner == amberPlayer.license),

                            gradeRank = crewGradeObject.rank,
                            gradeName = crewGradeObject.name,
                            gradeLabel = crewGradeObject.label,
                            gradeSalary = crewGradeObject.salary,
                            gradePermissions = crewGradeObject.permission,
                            gradeWhitelisted = crewGradeObject.whitelisted,
                        }

                        local amberCharacter = CreateAmberCharacter(source, characterData.unique_id, characterData.group, characterData.job, characterData.crew, accounts, {}, characterData.needs, characterData.ped_model, vector3(characterData.position_x, characterData.position_y, characterData.position_z), characterData.heading, characterData.isDead, characterData.status.health, characterData.status.armor)

                        amberPlayer.addCharacter(amberCharacter)
                        amberPlayer.setCurrentCharacter(characterData.unique_id)
                        amberCharacter.needs.initializeNeeds()

                        ABT.Players[source] = amberPlayer

                        MySQL.Async.execute('UPDATE characters SET needs = ? WHERE id = ?', { json.encode(amberCharacter.needs.getAllNeeds()), characterID, })

                        TriggerClientEvent('ambitions:playerLoaded', source, characterData, amberPlayer)
                        TriggerEvent('ambitions:server:onPlayerSpawn', source)
                        TriggerClientEvent('ambitions:client:StartNeedsThread', source)
                    end
                end)
            end)
        end)
    end)
end

--- Insert the user into the database if they are not already in it.
---@param source number The player's server ID.
---@param identifiers table The player's identifiers.
---@param amberPlayer table The player's Amber object.
local function InsertUser(source, identifiers, amberPlayer)
    local LICENSE <const> = identifiers.license
    local DISCORD_ID <const> = identifiers.discord
    local IP <const> = identifiers.ip

    if not LICENSE or not DISCORD_ID or not IP then
        ABT.Print.Log(3, 'Invalid player identifiers for player with source ID:', source)

        DropPlayer(source, 'Missing valid identifiers, please contact support.')
        return
    end

    local userQuery = [[
        INSERT INTO users (license, discord_id, ip)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE last_login = CURRENT_TIMESTAMP
    ]]

    MySQL.Async.execute(userQuery, {LICENSE, DISCORD_ID, IP}, function(rowsAffected)
        if debug.Spawn.DebugUser then
            ABT.Print.Log(5, rowsAffected .. " rows affected. User inserted for license:", LICENSE)
        end

        MySQL.Async.fetchScalar('SELECT id FROM users WHERE license = ?', {LICENSE}, function(userID)
            if not userID then
                ABT.Print.Log(3, 'Failed to retrieve user ID for license:', LICENSE)

                return
            end

            if debug.Spawn.DebugUser then
                ABT.Print.Log(5, 'User ID:', userID)
            end

            InsertOrFetchCharacter(source, userID, amberPlayer)
        end)
    end)
end

RegisterServerEvent('ambitions:server:spawnedPlayer', function()
    local source = source
    local PLAYER_IDENTIFIERS <const> = ABT.Player.GetPlayerIdentifier(source)
    local playerLicense = PLAYER_IDENTIFIERS.license

    if not playerLicense then
        ABT.Print.Log(3, 'Failed to retrieve license for source:', source)

        DropPlayer(source, 'Failed to retrieve your license. Please reconnect.')
        return
    end

    local checkQuery = 'SELECT id FROM users WHERE license = ?'

    MySQL.Async.fetchScalar(checkQuery, {playerLicense}, function(result)
        if debug.Spawn.DebugUser then
            ABT.Print.Log(5, 'USERS RESULT:', result)
        end

        if not result then
            if debug.Spawn.DebugUser then
                ABT.Print.Log(1, 'First connection detected for source:', source)
            end

            local amberPlayer = CreateAmberUser(source, playerLicense)
            if debug.Spawn.DebugUser then
                ABT.Print.Log(5, amberPlayer.source, amberPlayer.getLicense())
            end

            InsertUser(source, PLAYER_IDENTIFIERS, amberPlayer)
        else
            local userID = result

            if debug.Spawn.DebugUser then
                ABT.Print.Log(5, 'User found for source:', source, 'User ID:', userID)
            end

            local getCharacterQuery = 'SELECT id, unique_id, `group`, needs, ped_model, position_x, position_y, position_z, heading, `status`, isDead FROM characters WHERE user_id = ?'

            MySQL.Async.fetchAll(getCharacterQuery, {userID}, function(characterResult)
                if not characterResult then
                    ABT.Print.Log(3, 'Failed to retrieve character data for user_id:', userID)

                    DropPlayer(source, 'Failed to retrieve your character data. Please reconnect.')
                end

                for i = 1, #characterResult do
                    local characterData = characterResult[i]
                    characterData.status = json.decode(characterData.status)
                    characterData.isDead = characterData.isDead == 0
                    characterData.needs = json.decode(characterData.needs)

                    if debug.Spawn.DebugCharacter then
                        ABT.Print.Log(5, 'Character data found for user_id:', userID, 'Data:', characterData)
                    end

                    local getAccountsInfoQuery = 'SELECT account_type, account_amount, account_metadata FROM characters_accounts WHERE character_id = ?'
                    MySQL.Async.fetchAll(getAccountsInfoQuery, {characterData.id}, function(accountsInfo)
                        if debug.Spawn.DebugAccounts then
                            ABT.Print.Log(5, 'Accounts Info:', accountsInfo)
                        end

                        local accounts = {}
                        for _, accountInfo in ipairs(accountsInfo) do
                            accounts[accountInfo.account_type] = {
                                balance = accountInfo.account_amount,
                                metadata = json.decode(accountInfo.account_metadata)
                            }
                        end

                        if debug.Spawn.DebugAccounts then
                            ABT.Print.Log(5, 'Accounts:', accounts)
                        end

                        local retrieveJobQuery = [[
                            SELECT job, job_grade, on_duty_job, crew, crew_grade, on_duty_crew
                            FROM character_affiliations
                            WHERE character_id = ?
                        ]]

                        MySQL.Async.fetchAll(retrieveJobQuery, {characterData.id}, function(jobResult)
                            local characterAffiliation = {}

                            if debug.Spawn.DebugJobs then
                                ABT.Print.Log(5, 'Job Result:', jobResult)
                            end

                            for _, row in ipairs(jobResult) do
                                if not ABT.DoesSocietyExist(row.job, row.job_grade) then
                                    ABT.Print.Log(3, 'The job does not exist:', row.job, row.job_grade, '. Setting to unemployed.')
                                    row.job = 'unemployed'
                                    row.job_grade = 'unemployed'
                                    row.on_duty_job = 0
                                end

                                if not ABT.DoesCrewExist(row.crew, row.crew_grade) then
                                    ABT.Print.Log(3, 'The crew does not exist:', row.crew, row.crew_grade, '. Setting to none.')
                                    row.crew = 'none'
                                    row.crew_grade = 'none'
                                    row.on_duty_crew = 0
                                end

                                local jobObject = ABT.Societies[row.job]
                                local jobGradeObject = jobObject and jobObject.societyGrades.getGrade(row.job_grade) or nil
                                local crewObject = ABT.Crews[row.crew]
                                local crewGradeObject = crewObject and crewObject.crewGrades.getGrade(row.crew_grade) or nil

                                characterAffiliation = {
                                    job = row.job,
                                    job_grade = row.job_grade,
                                    on_duty_job = row.on_duty_job,
                                    crew = row.crew,
                                    crew_grade = row.crew_grade,
                                    on_duty_crew = row.on_duty_crew,
                                }

                                characterData.job = {
                                    name = jobObject.societyName,
                                    label = jobObject.societyLabel,
                                    isOwner = (jobObject.societyOwner == playerLicense),

                                    gradeRank = jobGradeObject.rank,
                                    gradeName = jobGradeObject.name,
                                    gradeLabel = jobGradeObject.label,
                                    gradeSalary = jobGradeObject.salary,
                                    gradePermissions = jobGradeObject.permission,
                                    gradeWhitelisted = jobGradeObject.whitelisted,
                                }

                                characterData.crew = {
                                    name = crewObject.crewName,
                                    label = crewObject.crewLabel,
                                    isOwner = (crewObject.crewOwner == playerLicense),

                                    gradeRank = crewGradeObject.rank,
                                    gradeName = crewGradeObject.name,
                                    gradeLabel = crewGradeObject.label,
                                    gradeSalary = crewGradeObject.salary,
                                    gradePermissions = crewGradeObject.permission,
                                    gradeWhitelisted = crewGradeObject.whitelisted,
                                }
                            end

                            local retrieveLicensesQuery = [[
                                SELECT license_type, license_status, license_metadata, granted_at, revoked_at
                                FROM character_licenses
                                WHERE character_unique_id = ?
                            ]]

                            MySQL.Async.fetchAll(retrieveLicensesQuery, {characterData.unique_id}, function(licensesResult)
                                local licenses = {}
                                ABT.Print.Log(5, 'Licenses Result:', licensesResult)
                                for _, licenseRow in ipairs(licensesResult) do
                                    licenses[licenseRow.license_type] = {
                                        type = licenseRow.license_type,
                                        status = licenseRow.license_status == 1,
                                        metadata = json.decode(licenseRow.license_metadata or "{}"),
                                        granted_at = licenseRow.granted_at,
                                        revoked_at = licenseRow.revoked_at
                                    }
                                end
                                ABT.Print.Log(5, 'Player Licenses', licenses)

                                local amberPlayer = CreateAmberUser(source, playerLicense)
                                local amberCharacter = CreateAmberCharacter(source, characterData.unique_id, characterData.group, characterData.job, characterData.crew, accounts, licenses, characterData.needs, characterData.ped_model, vector3(characterData.position_x, characterData.position_y, characterData.position_z), characterData.heading, characterData.isDead, characterData.status.health, characterData.status.armor)

                                amberPlayer.addCharacter(amberCharacter)
                                amberPlayer.setCurrentCharacter(characterData.unique_id)
                                ABT.Players[source] = amberPlayer

                                -- TriggerClientEvent('ambitions:client:loadCharacter', source, characterData)
                                TriggerClientEvent('ambitions:playerLoaded', source, characterData, amberPlayer)
                                TriggerEvent('ambitions:server:onPlayerSpawn', source)
                                TriggerClientEvent('ambitions:client:StartNeedsThread', source)

                                if debug.Spawn.DebugUser then
                                    ABT.Print.Log(5, 'Player Loaded with other players', ABT.Players)
                                end

                                local perms = ABT.HasPermissions(source)

                                if debug.Spawn.DebugAccounts then
                                    ABT.Print.Log(5, amberPlayer.getCurrentCharacter().accounts.getAccount('cash').balance)
                                end

                                if debug.Spawn.DebugCharacter then
                                    ABT.Print.Log(5, 'LOADING :', amberCharacter.getUniqueID(), amberCharacter.getGroup(), amberCharacter.getCharacterModel(), amberCharacter.getPosition(), amberCharacter.getHeading())
                                    ABT.Print.Log(5, 'Player Permissions', perms)
                                end
                            end)
                        end)
                    end)
                end
            end)
        end
    end)
end)