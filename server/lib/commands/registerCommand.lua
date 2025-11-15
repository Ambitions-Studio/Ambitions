amb = amb or {}
amb.commands = amb.commands or {}

local registeredCommands = {}

--- Validate and convert command arguments based on type
---@param args table The raw arguments from the command
---@param suggestion table The suggestion configuration with argument definitions
---@param source number The player source
---@return table | nil parsedArgs The parsed arguments or nil if validation failed
---@return string | nil error The error message if validation failed
local function ValidateArguments(args, suggestion, source)
    if not suggestion or not suggestion.arguments then
        return args, nil
    end

    if suggestion.validate then
        if #args ~= #suggestion.arguments then
            return nil, ("Invalid number of arguments. Expected %d, got %d"):format(#suggestion.arguments, #args)
        end
    end

    local parsedArgs = {}

    for index, argDef in ipairs(suggestion.arguments) do
        local rawValue = args[index]
        local argName = argDef.name
        local argType = argDef.type or "any"

        if argType == "number" then
            local numValue = tonumber(rawValue)
            if not numValue then
                return nil, ("Argument #%d (%s) must be a number"):format(index, argName)
            end
            parsedArgs[argName] = numValue

        elseif argType == "player" then
            local targetSource = tonumber(rawValue)

            if rawValue == "me" then
                targetSource = source
            end

            if not targetSource then
                return nil, ("Argument #%d (%s) must be a valid player ID"):format(index, argName)
            end

            local targetPlayer = amb.player.get(targetSource)
            if not targetPlayer then
                return nil, ("Player with ID %d not found"):format(targetSource)
            end

            parsedArgs[argName] = targetPlayer

        elseif argType == "string" then
            if not rawValue or rawValue == "" then
                return nil, ("Argument #%d (%s) must be a valid string"):format(index, argName)
            end
            parsedArgs[argName] = tostring(rawValue)

        elseif argType == "coordinate" then
            local coord = tonumber(rawValue)
            if not coord then
                return nil, ("Argument #%d (%s) must be a valid coordinate"):format(index, argName)
            end
            parsedArgs[argName] = coord

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

        if argDef.Validator and type(argDef.Validator.validate) == "function" then
            local candidate = parsedArgs[argName]
            local ok, result = pcall(argDef.Validator.validate, candidate)

            if not ok or result ~= true then
                return nil, argDef.Validator.err or ("Argument #%d (%s) validation failed"):format(index, argName)
            end
        end
    end

    return parsedArgs, nil
end

--- Register a command with permission checking and argument validation
---@param commandName string | table The command name or table of names
---@param permission string | nil The permission required (command name from permissionsConfig)
---@param callback function The callback function(source, args, showError)
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
        local command = registeredCommands[commandName]

        if source == 0 then
            if not command.allowConsole then
                amb.print.warning(("Command '%s' cannot be executed from console"):format(commandName))
                return
            end

            command.callback(0, args, function(msg)
                print(("[COMMAND] %s"):format(msg))
            end)
            return
        end

        if command.permission then
            if not amb.permissions.HasPermission(source, command.permission) then
                local player = amb.player.get(source)
                if player then
                    amb.print.warning(("Player %d attempted to use command '%s' without permission"):format(source, commandName))
                end
                return
            end
        end

        local parsedArgs = args
        local validationError = nil

        if command.suggestion and command.suggestion.arguments then
            parsedArgs, validationError = ValidateArguments(args, command.suggestion, source)

            if validationError then
                local player = amb.player.get(source)
                if player then
                    local character = player.getCurrentCharacter()
                    if character then
                        character.triggerEvent("ambitions:showNotification", {
                            type = "error",
                            message = validationError
                        })
                    end
                end
                return
            end
        end

        local player = amb.player.get(source)

        command.callback(player, parsedArgs, function(msg, msgType)
            if player then
                local character = player.getCurrentCharacter()
                if character then
                    character.triggerEvent("ambitions:showNotification", {
                        type = msgType or "info",
                        message = msg
                    })
                end
            end
        end)
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


amb.RegisterCommand('testCommand', 'admin', function()
end)