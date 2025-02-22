--- Class for character needs.
---@param needs table The needs of the character.
function CreateNeeds(needs)

    ---@class characterNeeds
    ---@field needs table The needs of the character.
    local self = {}
    self.needs = needs

    local function initializeNeeds()
        self.needs = {
            hunger = 100,
            thirst = 100,
            stress = 0,
            lifetimeAddictions = {},
            addictionTypes = {
                alcohol = 0,
                weed = 0,
                cocaine = 0,
                heroin = 0,
                gambling = 0
            }
        }
    end

    ---@param addictionType string The addiction to manage.
    ---@return void
---@param addictionType string The addiction to manage.
---@return void
local function manageLifetimeAddictions(addictionType)
    local currentLevel = self.needs.addictionTypes[addictionType]

    if currentLevel == 100 then
        if not ABT.Table.TableContains(self.needs.lifetimeAddictions, addictionType) then
            table.insert(self.needs.lifetimeAddictions, addictionType)
            ABT.Print.Log(1, ('Your character is now permanently addicted to %s.'):format(addictionType))
        end
    elseif currentLevel < 100 then
        local index = ABT.Table.IndexOf(self.needs.lifetimeAddictions, addictionType)[1]
        if index then
            table.remove(self.needs.lifetimeAddictions, index)
            ABT.Print.Log(3, ('Lifetime addiction %s removed.'):format(addictionType))
        end
    end
end

    ---@return void
    function self.initializeNeeds()
        initializeNeeds()
    end

    ---@return table needs The needs of the character.
    function self.getAllNeeds()
        return self.needs
    end

    ---@param need string The need to get.
    ---@return number | nil The value of the need.
    function self.getNeed(need)
        if self.needs[need] ~= nil then
            return self.needs[need]
        elseif self.needs.addictionTypes[need] ~= nil then
            return self.needs.addictionTypes[need]
        else
            ABT.Print.Log(3, ('Need %s does not exist.'):format(need))
            return nil
        end
    end

    ---@param need string The need to set the value of.
    ---@param value number The value to set the need to.
    ---@return void
    function self.setNeed(need, value)
        value = math.max(0, math.min(100, value))

        if self.needs[need] ~= nil then
            self.needs[need] = value
        elseif self.needs.addictionTypes[need] ~= nil then
            self.needs.addictionTypes[need] = value
            manageLifetimeAddictions(need)
        else
            ABT.Print.Log(3, ('Unable to set need %s. It does not exist.'):format(need))
        end
    end

    ---@param need string The need to modify.
    ---@param amount number The amount to modify the need by.
    ---@return void
    function self.modifyNeed(need, amount)
        if self.needs[need] ~= nil then
            self.needs[need] = math.max(0, math.min(100, self.needs[need] + amount))
        elseif self.needs.addictionTypes[need] ~= nil then
            local newValue = math.max(0, math.min(100, self.needs.addictionTypes[need] + amount))
            self.needs.addictionTypes[need] = newValue
            manageLifetimeAddictions(need)
        else
            ABT.Print.Log(3, ('Unable to modify need %s. It does not exist or the character is a lifetime addict.'):format(need))
        end
    end

    ---@param addictionType string The addiction type to add.
    ---@return void
    function self.addAddictionType(addictionType)
        if self.needs.addictionTypes[addictionType] == nil then
            self.needs.addictionTypes[addictionType] = 0
            ABT.Print.Log(1, ('Addiction type %s added with a default value of 0.'):format(addictionType))
        else
            ABT.Print.Log(3, ('Addiction type %s already exists.'):format(addictionType))
        end
    end

    ---@param addictionType string The addiction type to remove.
    ---@return void
    function self.removeAddictionType(addictionType)
        if self.needs.addictionTypes[addictionType] ~= nil then
            self.needs.addictionTypes[addictionType] = nil
            ABT.Print.Log(1, ('Addiction type %s removed from addictionTypes.'):format(addictionType))
        else
            ABT.Print.Log(3, ('Addiction type %s does not exist in addictionTypes.'):format(addictionType))
        end

        for i, lifetime in ipairs(self.needs.lifetimeAddictions) do
            if lifetime == addictionType then
                table.remove(self.needs.lifetimeAddictions, i)
                ABT.Print.Log(3, ('Lifetime addiction %s removed.'):format(addictionType))
                break
            end
        end
    end

    ---@return boolean isLifetimeAddicted Whether the character is a lifetime addict.
    ---@return table addictions The addictions the character has.
    function self.checkIsLifetimeAddict()
        if #self.needs.lifetimeAddictions > 0 then
            return true, self.needs.lifetimeAddictions
        else
            local normalAddictions = {}

            for addictionType, level in pairs(self.needs.addictionTypes) do
                if level > 0 then
                    normalAddictions[addictionType] = level
                end
            end

            return false, normalAddictions
        end
    end

    ---@return table criticalNeeds The critical needs of the character.
    function self.checkCriticalNeeds()
        local CRITICAL_THRESHOLDS <const> = {
            hunger = 15,
            thirst = 15,
            stress = 75,
            addiction = 75
        }
        local criticalNeeds = {}

        for need, threshold in pairs(CRITICAL_THRESHOLDS) do
            local value = self.needs[need]
            if value ~= nil and value <= threshold then
                table.insert(criticalNeeds, { need = need, level = "critical" })
            end
        end

        for addictionType, level in pairs(self.needs.addictionTypes) do
            if level >= CRITICAL_THRESHOLDS.addiction then
                table.insert(criticalNeeds, { need = addictionType, level = "high" })
            end
        end

        return criticalNeeds
    end

    return self
end