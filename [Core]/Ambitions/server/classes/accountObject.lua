---@param source number The source of the character.
---@param accounts table The accounts of the character.
function CreateAccount(source, accounts)

    ---@class characterAccounts
    ---@field accounts table The accounts of the character.
    local self = {}
    self.source = source
    self.accounts = accounts

    ---@param eventName string The name of the event.
    ---@vararg any The arguments to pass to the event.
    ---@return void
    function self.triggerEvent(eventName, ...)
        assert(type(eventName) == 'string', 'Event name must be a string.')
        TriggerClientEvent(eventName, self.source, ...)
    end

    ---@param accounts table The accounts to set to the character.
    ---@return void
    function self.setAccounts(accounts)
        self.accounts = accounts
    end

    ---@return table accounts The accounts of the character.
    function self.getAllAccounts()
        return self.accounts
    end

    ---@param accountName string The account to get.
    ---@return table account The account object of the account name.
    function self.getAccount(accountName)
        return self.accounts[accountName]
    end

    ---@param accountName string The account to get the balance of.
    ---@param balance number The balance of the account to set to.
    ---@return number balance The new balance of the account.
    function self.setAccountMoney(accountName, balance)
        if self.accounts[accountName] then
            self.accounts[accountName].balance = balance

            self.triggerEvent('ambitions:setAccountMoney', self.accounts[accountName])
            return self.accounts[accountName].balance
        else
            error(('Account %s does not exist.'):format(accountName))
        end
    end

    ---@param accountName string The account to add the money to.
    ---@param money number The money to add to the account.
    ---@return number balance The new balance of the account.
    function self.addAccountMoney(accountName, money)
        if self.accounts[accountName] then
            self.accounts[accountName].balance = self.accounts[accountName].balance + money

            self.triggerEvent('ambitions:setAccountMoney', self.accounts[accountName])
            return self.accounts[accountName].balance
        else
            error(('Account %s does not exist.'):format(accountName))
        end
    end

    ---@param accountName string The account to remove the money from.
    ---@param money number The money to remove from the account.
    ---@return number balance The new balance of the account.
    function self.removeAccountMoney(accountName, money)
        if self.accounts[accountName] then
            if self.accounts[accountName].balance >= money then
                self.accounts[accountName].balance = self.accounts[accountName].balance - money

                self.triggerEvent('ambitions:setAccountMoney', self.accounts[accountName])
                return self.accounts[accountName].balance
            else
                error(('Insufficient funds in account %s.'):format(accountName))
            end
        else
            error(('Account %s does not exist.'):format(accountName))
        end
    end

    ---@param accountName string The account to set the metadata of.
    ---@param metadata table The metadata to set to the account.
    ---@return void
    function self.setMetadataOfAccount(accountName, metadata)
        if self.accounts[accountName] then
            self.accounts[accountName].metadata = metadata
        else
            error(('Account %s does not exist.'):format(accountName))
        end
    end

    ---@param accountName string The account to get the metadata of.
    ---@return table metadata The metadata of the account.
    function self.getMetadataOfAccount(accountName)
        if self.accounts[accountName] then
            return self.accounts[accountName].metadata or {}
        else
            error(('Account %s does not exist.'):format(accountName))
        end
    end

    return self
end