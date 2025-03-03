local registeredCommands = {}

--- Check if a player has the required permissions
---@param source number The player's server ID
---@param requiredPermission string | table The required permission(s)
---@return boolean
local function PlayerHasPermissions(source, requiredPermission)
    local permissions = ABT.HasPermissions(source)
    if not permissions.open then
        return false
    end

    if type(requiredPermission) == "table" then
        for _, perm in ipairs(requiredPermission) do
            if permissions.Command and permissions.Command[perm] then
                return true
            end
        end
    else
        return permissions.Command and permissions.Command[requiredPermission] or false
    end

    return false
end

--- Register a command to the server
---@param commandName string | string[] The name(s) of the command
---@param requiredPermission string | table The permission(s) required to execute the command
---@param callback function The callback function of the command
---@param isAllowConsole boolean Whether the command can be executed from the console
---@param suggestion table | nil The suggestion of the command
---@return void
function ABT.RegisterCommand(commandName, requiredPermission, callback, isAllowConsole, suggestion)
    if type(commandName) == "table" then
        for _, name in ipairs(commandName) do
            ABT.RegisterCommand(name, requiredPermission, callback, isAllowConsole, suggestion)
        end
        return
    end

    if registeredCommands[commandName] then
        ABT.Print.Log(3, ("Command '%s' is already registered, overriding the command."):format(commandName))
        if registeredCommands[commandName].suggestion then
            TriggerClientEvent('chat:removeSuggestion', -1, "/" .. commandName)
        end
    end

    registeredCommands[commandName] = {
        requiredPermission = requiredPermission,
        callback = callback,
        isAllowConsole = isAllowConsole,
        suggestion = suggestion
    }

    if suggestion then
        TriggerClientEvent('chat:addSuggestion', -1, "/" .. commandName, suggestion.help, suggestion.args)
    end

    RegisterCommand(commandName, function(source, args)
        local command = registeredCommands[commandName]

        local function HandleCommandErrors(message)
            if source == 0 then
                ABT.Print.Log(3, message)
            else
                ABT.Print.Log(3, ("Error for player [%s]: %s"):format(source, message))
            end
        end

        if not command.isAllowConsole and source == 0 then
            HandleCommandErrors(("The command '%s' cannot be executed from the console."):format(commandName))
            return
        end

        local hasPermission = source == 0 and command.isAllowConsole or PlayerHasPermissions(source, command.requiredPermission)
        if not hasPermission then
            HandleCommandErrors(("You do not have permission to use the command '%s'."):format(commandName))
            return
        end

        if command.suggestion then
            local parsedArgs = {}
            local suggestionArgs = command.suggestion.args or {}
            local validate = command.suggestion.validate

            if validate and #args ~= #suggestionArgs then
                HandleCommandErrors(("Invalid number of arguments for the command '%s': expected %d, got %d.")
                    :format(commandName, #suggestionArgs, #args))
                return
            end

            for i, argConfig in ipairs(suggestionArgs) do
                local arg = args[i]
                if argConfig.type == "number" then
                    local numberArg = tonumber(arg)
                    if not numberArg then
                        HandleCommandErrors(("Argument #%d must be a number."):format(i))
                        return
                    end
                    parsedArgs[argConfig.name] = numberArg
                elseif argConfig.type == "string" then
                    if not arg or arg == "" then
                        HandleCommandErrors(("Argument #%d must be a string."):format(i))
                        return
                    end
                    parsedArgs[argConfig.name] = arg

                -- Command for item
                elseif argConfig.type == 'item' then
                    local item = ABT.Items[arg]
                    if not item then
                        HandleCommandErrors(("Argument #%d must be a valid item name."):format(i))
                        return
                    end
                    parsedArgs[argConfig.name] = item
                elseif argConfig.type == "player" or argConfig.type == "playerId" then
                    local target = tonumber(arg) or (arg == "me" and source)
                    if not target or not ABT.GetPlayerFromId(target) then
                        HandleCommandErrors(("Argument #%d must be a valid player ID."):format(i))
                        return
                    end
                    parsedArgs[argConfig.name] = ABT.GetPlayerFromId(target)
                else
                    parsedArgs[argConfig.name] = arg
                end
            end
            args = parsedArgs
        end

        local player = ABT.GetPlayerFromId(source)
        callback(player, args, function(responseMessage)
            ABT.Print.Log(1, responseMessage)
        end)
    end, true)
end

return ABT.RegisterCommand