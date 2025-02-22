--- Class for society Object
---@param societyName string The name of the society
---@param societyLabel string The label of the society
---@param societyOwner string The society's owner license
---@param societyIban string The society's IBAN
---@param societyMoney number The society's money
---@param isSocietyWhitelisted boolean If the society is whitelisted or not
---@param societyGrades table The society's grades
function HandleSociety(societyName, societyLabel, societyOwner, societyIban, societyMoney, isSocietyWhitelisted, societyGrades)
    ---@class SocietyObject
    ---@field societyName string The name of the society
    ---@field societyLabel string The label of the society
    ---@field societyOwner string The society's owner license
    ---@field societyIban string The society's IBAN
    ---@field societyMoney number The society's money
    ---@field isSocietyWhitelisted boolean If the society is whitelisted or not
    ---@field societyGrades table The society's grades
    local self = {}
    self.societyName = societyName
    self.societyLabel = societyLabel
    self.societyOwner = societyOwner
    self.societyIban = societyIban
    self.societyMoney = societyMoney
    self.isSocietyWhitelisted = isSocietyWhitelisted
    self.societyGrades = HandleSocietyGrade(societyGrades)


    ---@return string The society's name
    function self.getSocietyName()
        return self.societyName
    end

    ---@param name string The society's name
    function self.setSocietyName(name)
        assert(type(name) == 'string', 'The society name must be a string.')
        self.societyName = name
    end

    ---@return string The society's label
    function self.getSocietyLabel()
        return self.societyLabel
    end

    ---@param label string The society's label
    function self.setSocietyLabel(label)
        assert(type(label) == 'string', 'The society label must be a string.')
        self.societyLabel = label
    end

    ---@return string The society's owner license
    function self.getSocietyOwner()
        return self.societyOwner
    end

    ---@param newOwner string The new society's owner license
    function self.addSocietyOwner(newOwner)
        assert(type(newOwner) == 'string', 'The society owner must be a string.')
        self.societyOwner = newOwner
    end

    ---@return void
    function self.removeSocietyOwner()
        self.societyOwner = nil
    end

    ---@return string The society's IBAN
    function self.getSocietyIban()
        return self.societyIban
    end

    ---@param iban string The society's IBAN
    function self.setSocietyIban(iban)
        assert(type(iban) == 'string', 'The society IBAN must be a string.')
        self.societyIban = iban
    end

    ---@return number The society's money
    function self.getSocietyMoney()
        return self.societyMoney
    end

    ---@param amount number The amount to add to the society's money
    function self.addSocietyMoney(amount)
        assert(type(amount) == 'number', 'The amount must be a number.')
        assert(amount > 0, 'The amount must be a positive number.')
        self.societyMoney = self.societyMoney + amount
    end

    ---@param amount number The amount to remove from the society's money
    function self.removeSocietyMoney(amount)
        assert(type(amount) == 'number', 'The amount must be a number.')
        assert(amount > 0, 'The amount must be a positive number.')
        if self.societyMoney >= amount then
            self.societyMoney = self.societyMoney - amount
        else
            ABT.Print.Log(3, 'The society does not have enough money to remove.')
        end
    end

    ---@param amount number The amount to set the society's money
    function self.setSocietyMoney(amount)
        assert(type(amount) == 'number', 'The amount must be a number.')
        assert(amount >= 0, 'The amount must be a positive number.')
        self.societyMoney = amount
    end

    ---@return boolean If the society is whitelisted or not
    function self.getWhitelistedStatus()
        return self.isSocietyWhitelisted
    end

    ---@return void
    function self.setSocietyWhitelisted()
        self.isSocietyWhitelisted = true
    end

    ---@return void
    function self.setSocietyNotWhitelisted()
        self.isSocietyWhitelisted = false
    end

    return self
end