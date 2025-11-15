--- Set player role command
amb.RegisterCommand("setrole", "ambitioneer.setRole", function(source, args, showMessage)
    local isConsole = (source == 0)

    local targetPlayer = amb.player.get(args.target)
    if not targetPlayer then
        if isConsole then
            print(("[ERROR] Player with ID %d not found"):format(args.target))
        else
            showMessage(("Player with ID %d not found"):format(args.target), "error")
        end
        return
    end

    local targetCharacter = targetPlayer.getCurrentCharacter()
    if not targetCharacter then
        if isConsole then
            print(("[ERROR] Target player has no active character"):format(args.target))
        else
            showMessage("Target player has no active character", "error")
        end
        return
    end

    if not amb.permissions.RoleExists(args.role) then
        if isConsole then
            print(("[ERROR] Role '%s' does not exist"):format(args.role))
        else
            showMessage(("Role '%s' does not exist"):format(args.role), "error")
        end
        return
    end

    local oldRole = targetCharacter.getGroup()
    targetCharacter.setGroup(args.role)

    local targetName = targetCharacter.getFullName()
    local successMessage = ("Role changed: %s (%s -> %s)"):format(targetName, oldRole, args.role)

    if isConsole then
        print(("[SUCCESS] " .. successMessage))
    else
        local executor = amb.player.get(source)
        local executorCharacter = executor.getCurrentCharacter()
        showMessage(successMessage, "success")

        amb.print.info(("%s changed %s's role from '%s' to '%s'"):format(
            executorCharacter.getFullName(),
            targetName,
            oldRole,
            args.role
        ))
    end
end, {
    allowConsole = true,
    suggestion = {
        help = "Change a player's role",
        validate = true,
        arguments = {
            { name = "target", type = "number", help = "Player session ID" },
            { name = "role", type = "string", help = "Role name (user, admin, ambitioneer)" }
        }
    }
})