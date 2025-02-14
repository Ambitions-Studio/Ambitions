--- Class for crew Object
---@param crewName string The name of the crew
---@param crewLabel string The label of the crew
---@param crewOwner string The crew's owner license
---@param crewMoney number The crew's money
---@param isCrewWhitelisted boolean If the crew is whitelisted or not
---@param crewGrades table The crew's grades
function HandleCrew(crewName, crewLabel, crewOwner, crewMoney, isCrewWhitelisted, crewGrades)
    ---@class CrewObject
    ---@field crewName string The name of the crew
    ---@field crewLabel string The label of the crew
    ---@field crewOwner string The crew's owner license
    ---@field crewMoney number The crew's money
    ---@field whitelistedStatus boolean If the crew is whitelisted or not
    ---@field crewGrades table The crew's grades
    local self = {}
    self.crewName = crewName
    self.crewLabel = crewLabel
    self.crewOwner = crewOwner
    self.crewMoney = crewMoney
    self.whitelistedStatus = isCrewWhitelisted
    self.crewGrades = HandleCrewGrade(crewGrades)

    ---@return string The crew's name
    function self.getCrewName()
        return self.crewName
    end

    ---@param name string The crew's name
    function self.setCrewName(name)
        assert(type(name) == 'string', 'The crew name must be a string.')
        self.crewName = name
    end

    ---@return string The crew's label
    function self.getCrewLabel()
        return self.crewLabel
    end

    ---@param label string The crew's label
    function self.setCrewLabel(label)
        assert(type(label) == 'string', 'The crew label must be a string.')
        self.crewLabel = label
    end

    ---@return string The crew's owner license
    function self.getCrewOwner()
        return self.crewOwner
    end

    ---@param newOwner string The new crew's owner license
    function self.addCrewOwner(newOwner)
        assert(type(newOwner) == 'string', 'The crew owner must be a string.')
        self.crewOwner = newOwner
    end

    ---@return void
    function self.removeCrewOwner()
        self.crewOwner = nil
    end

    ---@return number The crew's money
    function self.getCrewMoney()
        return self.crewMoney
    end

    ---@param money number The amount to add to the crew's money
    function self.addCrewMoney(money)
        assert(type(money) == 'number', 'The crew money must be a number.')
        assert(money > 0, 'The crew money must be a positive number greater than 0.')
        self.crewMoney = self.crewMoney + money
    end

    ---@param money number The amount to remove from the crew's money
    function self.removeCrewMoney(money)
        assert(type(money) == 'number', 'The crew money must be a number.')
        assert(money > 0, 'The crew money must be a positive number greater than 0.')
        if self.crewMoney >= money then
            self.crewMoney = self.crewMoney - money
        else
            ABT.Print.Log(3, 'The crew does not have enough money to remove.')
        end
    end

    ---@param money number The amount to set the crew's money
    function self.setCrewMoney(money)
        assert(type(money) == 'number', 'The crew money must be a number.')
        assert(money >= 0, 'The crew money must be 0 or a positive number.')
        self.crewMoney = money
    end

    ---@return boolean If the crew is whitelisted or not
    function self.isCrewWhitelisted()
        return self.whitelistedStatus
    end

    ---@return void
    function self.setCrewWhitelisted()
        self.whitelistedStatus = true
    end

    ---@return void
    function self.removeCrewWhitelisted()
        self.whitelistedStatus = false
    end

    return self
end
