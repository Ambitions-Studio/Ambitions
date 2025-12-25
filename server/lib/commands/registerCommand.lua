amb = amb or {}
amb.commands = amb.commands or {}

local registeredCommands = {}

--- Validate and convert command arguments based on type
---@param args table The raw arguments from the command
---@param suggestion table The suggestion configuration with argument definitions
---@param sessionId number The player session ID
---@return table | nil parsedArgs The parsed arguments or nil if validation failed
---@return string | nil error The error message if validation failed
local function ValidateArguments(args, suggestion, sessionId)
    if not suggestion or not suggestion.arguments then
        return args, nil
    end

    if suggestion.validate then
        if #args ~= #suggestion.arguments then
            return nil, ("Invalid number of arguments. Expected %d, got %d"):format(#suggestion.arguments, #args)
        end
    end

    local parsedArgs = {}
    local err = nil

    for index, argDef in ipairs(suggestion.arguments) do
        local rawValue = args[index]
        local argName = argDef.name
        local argType = argDef.type or "any"

        if argType == "number" then
            local numValue = tonumber(rawValue)
            if not numValue then
                err = ("Argument #%d (%s) must be a number"):format(index, argName)
            else
                parsedArgs[argName] = numValue
            end

        elseif argType == "player" then
            local targetSessionId = tonumber(rawValue)

            if rawValue == "me" then
                targetSessionId = sessionId
            end

            if not targetSessionId then
                err = ("Argument #%d (%s) must be a valid player ID"):format(index, argName)
            else
                local targetPlayer = amb.cache.getPlayer(targetSessionId)
                if targetPlayer then
                    parsedArgs[argName] = targetPlayer
                else
                    err = ("Player with ID %d not found"):format(targetSessionId)
                end
            end

        elseif argType == "string" then
            if not rawValue or rawValue == "" then
                err = ("Argument #%d (%s) must be a valid string"):format(index, argName)
            else
                parsedArgs[argName] = tostring(rawValue)
            end

        elseif argType == "coordinate" then
            local coord = tonumber(rawValue)
            if not coord then
                err = ("Argument #%d (%s) must be a valid coordinate"):format(index, argName)
            else
                parsedArgs[argName] = coord
            end

        elseif argType == "item" then
            if not settingsConfig.useAmbitionsInventory then
                err = "Ambitions-Inventory is not enabled"
            elseif not rawValue or rawValue == "" then
                err = ("Argument #%d (%s) must be a valid item name"):format(index, argName)
            else
                local itemName = tostring(rawValue)
                local itemLabel = exports['Ambitions-Inventory']:GetItemLabel(itemName)
                if not itemLabel then
                    err = ("Item with name '%s' does not exist"):format(itemName)
                else
                    parsedArgs[argName] = itemName
                end
            end

        elseif argType == "merge" then
            local length = 0
            for i = 1, index - 1 do
                if args[i] then
                    length = length + string.len(args[i]) + 1
                end
            end
            local merged = table.concat(args, " ")
            parsedArgs[argName] = string.sub(merged, length + 1)

        elseif argType == "any" then
            parsedArgs[argName] = rawValue

        else
            parsedArgs[argName] = rawValue
        end

        if argDef.Validator and type(argDef.Validator.validate) == "function" and not err then
            local candidate = parsedArgs[argName]
            local ok, result = pcall(argDef.Validator.validate, candidate)

            if not ok or result ~= true then
                err = argDef.Validator.err or ("Argument #%d (%s) validation failed"):format(index, argName)
            end
        end

        if err then
            break
        end
    end

    if err then
        return nil, err
    end

    return parsedArgs, nil
end

--- Register a command with permission checking and argument validation
---@param commandName string | table The command name or table of names
---@param permission string | nil The permission required (e.g., "admin.getCoords")
---@param callback function The callback function(player, args, showError)
---@param options table | nil Optional configuration { allowConsole: boolean, suggestion: table }
function amb.RegisterCommand(commandName, permission, callback, options)
    if type(commandName) == "table" then
        for _, name in ipairs(commandName) do
            amb.RegisterCommand(name, permission, callback, options)
        end
        return
    end

    options = options or {}
    local allowConsole = options.allowConsole or false
    local suggestion = options.suggestion

    if registeredCommands[commandName] then
        amb.print.warning(("Command '%s' already registered, overriding"):format(commandName))

        if registeredCommands[commandName].suggestion then
            TriggerClientEvent("chat:removeSuggestion", -1, "/" .. commandName)
        end
    end

    if suggestion then
        suggestion.arguments = suggestion.arguments or {}
        suggestion.help = suggestion.help or ""

        TriggerClientEvent("chat:addSuggestion", -1, "/" .. commandName, suggestion.help, suggestion.arguments)
    end

    registeredCommands[commandName] = {
        permission = permission,
        callback = callback,
        allowConsole = allowConsole,
        suggestion = suggestion
    }

    RegisterCommand(commandName, function(source, args)
        local sessionId = source
        local command = registeredCommands[commandName]

        if not command.allowConsole and sessionId == 0 then
            amb.print.warning(("Command '%s' cannot be executed from console"):format(commandName))
            return
        end

        local player = sessionId ~= 0 and amb.cache.getPlayer(sessionId) or false
        local err = nil

        if command.permission and sessionId ~= 0 then
            if not amb.permissions.HasPermission(sessionId, command.permission) then
                amb.print.warning(("Player %d attempted to use command '%s' without permission"):format(sessionId, commandName))
                TriggerClientEvent('amb:showNotification', sessionId, 'Permission Denied', 'You do not have permission to use this command', 'error', 5000, 'top-right')
                return
            end
        end

        if command.suggestion and command.suggestion.arguments then
            args, err = ValidateArguments(args, command.suggestion, sessionId)
        end

        if err then
            if sessionId == 0 then
                amb.print.error(err)
            else
                TriggerClientEvent('amb:showNotification', sessionId, 'Command Error', err, 'error', 5000, 'top-right')
            end
        else
            command.callback(player, args, function(msg, msgType)
                if sessionId == 0 then
                    amb.print.info(("[COMMAND] %s"):format(msg))
                else
                    TriggerClientEvent('amb:showNotification', sessionId, 'Command', msg, msgType or 'info', 5000, 'top-right')
                end
            end)
        end
    end, true)
end

--- Get all registered commands
---@return table commands All registered commands
function amb.commands.GetAll()
    return registeredCommands
end

--- Check if a command is registered
---@param commandName string The command name to check
---@return boolean isRegistered Whether the command is registered
function amb.commands.IsRegistered(commandName)
    return registeredCommands[commandName] ~= nil
end

--- Unregister a command
---@param commandName string The command name to unregister
---@return boolean success Whether the command was unregistered
function amb.commands.Unregister(commandName)
    if not registeredCommands[commandName] then
        return false
    end

    if registeredCommands[commandName].suggestion then
        TriggerClientEvent("chat:removeSuggestion", -1, "/" .. commandName)
    end

    registeredCommands[commandName] = nil
    return true
end

amb.print.success("Command Registration System loaded successfully")
