---@param source number The source of the character.
---@param uniqueID string The unique ID of the character.
---@param group string The group of the character.
---@param job table The job of the character.
---@param crew table The crew of the character.
---@param accounts characterAccounts The accounts object of the character.
---@param licenses table The licenses of the character.
---@param characterModel string The model of the character.
---@param position table The position of the character.
---@param heading number The heading of the character.
---@param isDead boolean Whether the character is dead.
---@param health number The health of the character.
---@param armor number The armor of the character.
function CreateAmberCharacter(source, uniqueID, group, job, crew, accounts, licenses, needs, characterModel, position, heading, isDead, health, armor)

    ---@class amberCharacter
    ---@field source number The source of the character.
    ---@field uniqueID string The unique ID of the character.
    ---@field group string The group of the character.
    ---@field job table The job of the character.
    ---@field crew table The crew of the character.
    ---@field accounts characterAccounts The accounts object of the character.
    ---@field licenses table The licenses of the character.
    ---@field characterModel string The model of the character.
    ---@field position table The position of the character.
    ---@field heading number The heading of the character.
    ---@field isDead boolean Whether the character is dead.
    ---@field health number The health of the character.
    ---@field armor number The armor of the character.
    local self = {}
    self.source = source
    self.uniqueID = uniqueID
    self.group = group
    self.job = job
    self.crew = crew
    self.accounts = CreateAccount(source, accounts)
    self.licenses = licenses or {}
    self.needs = CreateNeeds(needs)
    self.characterModel = characterModel
    self.position = position
    self.heading = heading
    self.isDead = isDead
    self.health = health
    self.armor = armor

    ---@param eventName string The name of the event.
    ---@vararg any The arguments to pass to the event.
    ---@return void
    function self.triggerEvent(eventName, ...)
        assert(type(eventName) == 'string', 'Event name must be a string.')
        TriggerClientEvent(eventName, self.source, ...)
    end

    ---@return number source The source of the character.
    function self.getCharacterId()
        return self.source
    end

    ---@return string uniqueID The unique ID of the character.
    function self.getUniqueID()
        return self.uniqueID
    end

    ---@param group string The group of the character.
    ---@return void
    function self.setGroup(group)
        local lastGroup = self.group

        self.group = group

        self.triggerEvent('ambitions:setGroup', self.group, lastGroup)
    end

    ---@return string group The group of the character.
    function self.getGroup()
        return self.group
    end

    ---@return table The job of the character.
    function self.getJob()
        return self.job
    end

    ---@return string The name of the grade of the character.
    function self.getJobGrade()
        return self.job.gradeLabel
    end

    function self.setJob(jobName, jobGrade)
        if not ABT.Societies[jobName] then
            ABT.Print.Log(3, ("The job '%s' does not exist."):format(jobName))
            return false
        end

        local jobObject = ABT.Societies[jobName]
        local jobGradeObject = jobObject and jobObject.societyGrades.getGrade(jobGrade)

        if not jobGradeObject then
            ABT.Print.Log(3, ("The grade '%s' does not exist for the job '%s'."):format(jobGrade, jobName))
            return false
        end

        self.job = {
            name = jobObject.societyName,
            label = jobObject.societyLabel,
            isOwner = (jobObject.societyOwner == ABT.Players[self.source].license),

            gradeRank = jobGradeObject.rank,
            gradeName = jobGradeObject.name,
            gradeLabel = jobGradeObject.label,
            gradeSalary = jobGradeObject.salary,
            gradePermissions = jobGradeObject.permission,
            gradeWhitelisted = jobGradeObject.whitelisted,
        }

        MySQL.Async.execute(
            "UPDATE character_affiliations SET job = ?, job_grade = ? WHERE character_id = ?",
            { self.job.name, self.job.gradeName, self.uniqueID }
        )

        return true
    end

    ---@return table The crew of the character.
    function self.getCrew()
        return self.crew
    end

    ---@return string The name of the grade of the crew.
    function self.getCrewGrade()
        return self.crew.gradeLabel
    end

    function self.setCrew(crewName, crewGrade)
        if not ABT.Crews[crewName] then
            ABT.Print.Log(3, ("The crew '%s' does not exist."):format(crewName))
            return false
        end

        local crewObject = ABT.Crews[crewName]
        local crewGradeObject = crewObject and crewObject.crewGrades.getGrade(crewGrade)

        if not crewGradeObject then
            ABT.Print.Log(3, ("The grade '%s' does not exist for the job '%s'."):format(crewGrade, crewName))
            return false
        end

        self.crew = {
            name = crewObject.crewName,
            label = crewObject.crewLabel,
            isOwner = (crewObject.crewOwner == ABT.Players[self.source].license),

            gradeRank = crewGradeObject.rank,
            gradeName = crewGradeObject.name,
            gradeLabel = crewGradeObject.label,
            gradeSalary = crewGradeObject.salary,
            gradePermissions = crewGradeObject.permission,
            gradeWhitelisted = crewGradeObject.whitelisted,
        }

        MySQL.Async.execute(
            "UPDATE character_affiliations SET crew = ?, crew_grade = ? WHERE character_id = ?",
            { self.crew.name, self.crew.gradeName, self.uniqueID }
        )

        return true
    end

    ---@param licenseType string The type of the license.
    ---@return boolean Whether the character has the license.
    function self.hasLicense(licenseType)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        return self.licenses[licenseType] ~= nil
    end

    ---@param licenseType string The type of the license.
    ---@param metadata table | nil The metadata of the license.
    function self.grantLicense(licenseType, metadata)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        MySQL.Async.fetchScalar("SELECT 1 FROM licenses WHERE license_type = ?", { licenseType }, function(exists)
            if not exists then
                ABT.Print.Log(3, ("The license '%s' does not exist."):format(licenseType))
                return
            end

            self.licenses[licenseType] = {
                type = licenseType,
                status = true,
                metadata = metadata or {},
                grantedAt = os.date('%Y-%m-%d %H:%M:%S'),
            }

            MySQL.Async.execute([[
            INSERT INTO character_licenses (character_unique_id, license_type, license_status, license_metadata, granted_at)
            VALUES (?, ?, 1, ?, NOW())
            ON DUPLICATE KEY UPDATE license_status = 1, granted_at = NOW(), license_metadata = VALUES(license_metadata)
        ]], { self.uniqueID, licenseType, json.encode(metadata or {}) })

            ABT.Print.Log(5, ("License '%s' granted to player '%s'."):format(licenseType, self.uniqueID))
        end)
    end

    ---@param licenseType string The type of the license.
    function self.revokeLicense(licenseType)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        if not self.hasLicense(licenseType) then
            ABT.Print.Log(3, ("Player '%s' does not have the license '%s' to revoke."):format(self.uniqueID, licenseType))
            return
        end

        self.licenses[licenseType].status = false
        self.licenses[licenseType].revokedAt = os.date('%Y-%m-%d %H:%M:%S')

        MySQL.Async.execute([[
        UPDATE character_licenses
        SET license_status = 0, revoked_at = NOW()
        WHERE character_unique_id = ? AND license_type = ?
    ]], { self.uniqueID, licenseType })

        ABT.Print.Log(5, ("License '%s' revoked for player '%s'."):format(licenseType, self.uniqueID))
    end

    ---@param licenseType string The type of the license.
    function self.removeLicense(licenseType)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        if not self.hasLicense(licenseType) then
            ABT.Print.Log(3, ("Player '%s' does not have the license '%s' to remove."):format(self.uniqueID, licenseType))
            return
        end

        self.licenses[licenseType] = nil

        MySQL.Async.execute("DELETE FROM character_licenses WHERE character_unique_id = ? AND license_type = ?", { self.uniqueID, licenseType })

        ABT.Print.Log(5, ("License '%s' removed for player '%s'."):format(licenseType, self.uniqueID))
    end

    ---@param licenseType string The type of the license.
    function self.reactivateLicense(licenseType)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        if not self.hasLicense(licenseType) then
            ABT.Print.Log(3, ("Player '%s' does not have the license '%s' to reactivate."):format(self.uniqueID, licenseType))
            return
        end

        if self.licenses[licenseType].status then
            ABT.Print.Log(3, ("The license '%s' is already active for player '%s'."):format(licenseType, self.uniqueID))
            return
        end

        self.licenses[licenseType].status = true
        self.licenses[licenseType].revokedAt = nil

        MySQL.Async.execute("UPDATE character_licenses SET license_status = 1, revoked_at = NULL WHERE character_unique_id = ? AND license_type = ?", { self.uniqueID, licenseType }, function(affectedRows)
            if affectedRows > 0 then
                ABT.Print.Log(5, ("License '%s' reactivated for player '%s'."):format(licenseType, self.uniqueID))
            else
                ABT.Print.Log(3, ("Failed to reactivate license '%s' for player '%s'."):format(licenseType, self.uniqueID))
            end
        end)
    end

    ---@param licenseType string The type of the license.
    ---@param metadata table The metadata of the license.
    function self.updateLicenseMetadata(licenseType, metadata)
        assert(type(licenseType) == 'string', 'The license type must be a string.')
        assert(type(metadata) == 'table', 'The metadata must be a table.')

        if not self.hasLicense(licenseType) then
            ABT.Print.Log(3, ("Player '%s' does not have the license '%s' to update metadata."):format(self.uniqueID, licenseType))
            return
        end

        self.licenses[licenseType].metadata = metadata

        MySQL.Async.execute("UPDATE character_licenses SET license_metadata = ? WHERE character_unique_id = ? AND license_type = ?", { json.encode(metadata), self.uniqueID, licenseType })

        ABT.Print.Log(5, ("Metadata updated for license '%s' for player '%s'."):format(licenseType, self.uniqueID))
    end

    ---@return table The licenses of the character.
    function self.getAllLicenses()
        return self.licenses
    end

    ---@param characterModel string The model of the character.
    ---@return void
    function self.setCharacterModel(characterModel)
        self.characterModel = characterModel
    end

    ---@return string characterModel The model of the character.
    function self.getCharacterModel()
        return self.characterModel
    end

    ---@param position table | vecotr3 | vector4 The position of the character.
    ---@return void
    function self.setPosition(position)
        local ped <const> = self.source
        local vector = type(position) == 'vector4' and position or type(position) == 'vector3' and vector4(position, 0.0) or vec(position.x, position.y, position.z, position.heading or 0.0)

        SetEntityCoords(ped, vector.x, vector.y, vector.z, false, false, false, true)
        SetEntityHeading(ped, vector.w)
        self.position = position
    end

    ---@return table position The position of the character.
    function self.getPosition()
        return self.position
    end

    ---@param position table The position of the character.
    ---@return void
    function self.savePosition(position)
        self.position = position
    end

    ---@param heading number The heading of the character.
    ---@return void
    function self.saveHeading(heading)
        self.heading = heading
    end

    ---@return number heading The heading of the character.
    function self.getHeading()
        return self.heading
    end

    ---@param isDead boolean Whether the character is dead.
    ---@return void
    function self.setDeathState(isDead)
        self.isDead = isDead
    end

    ---@return boolean isDead Whether the character is dead.
    function self.getDeathState()
        return self.isDead
    end

    ---@param health number The health of the character.
    ---@return void
    function self.setHealth(health)
        self.health = math.max(0, math.min(200, tonumber(health) or 0))

        self.triggerEvent('ambitions:character:updateHealth', self.health)
    end

    ---@return number health The health of the character.
    function self.getHealth()
        return self.health
    end

    ---@param armor number The armor of the character.
    ---@return void
    function self.setArmor(armor)
        self.armor = math.max(0, math.min(100, tonumber(armor) or 0))
    end

    ---@return number armor The armor of the character.
    function self.getArmor()
        return self.armor
    end

    ---@return table status The status of the character.
    function self.getStatus()
        return {
            health = self.health,
            armor = self.armor
        }
    end





    for _, funcs in pairs(ABT.PlayerFunctionOverrides) do
        for fnName, fn in pairs(funcs) do
            self[fnName] = fn(self)
        end
    end

    return self
end