--- Test needs command
amb.RegisterCommand("testneed", "ambitioneer.testNeed", function(player, args, showMessage)
    if not player then
        return showMessage("This command can only be used by players", "error")
    end

    local character = player.getCurrentCharacter()
    if not character then
        return showMessage("You have no active character", "error")
    end

    local needs = character.getNeeds()
    local needsMessage = "Your needs:"

    for needType, value in pairs(needs) do
        needsMessage = needsMessage .. ("\n  %s: %d/100"):format(needType, value)
    end

    showMessage(needsMessage, "info")
end, {
    allowConsole = false,
    suggestion = {
        help = "Display your current needs levels",
        validate = false
    }
})

--- Set player role command
amb.RegisterCommand("setrole", "ambitioneer.setRole", function(player, args, showMessage)
    if not amb.permissions.RoleExists(args.role) then
        return showMessage(("Role '%s' does not exist"):format(args.role), "error")
    end

    local targetCharacter = args.target.getCurrentCharacter()
    if not targetCharacter then
        return showMessage("Target player has no active character", "error")
    end

    local oldRole = targetCharacter.getGroup()
    targetCharacter.setGroup(args.role)

    local targetName = targetCharacter.getFullName()
    local successMessage = ("Role changed: %s (%s -> %s)"):format(targetName, oldRole, args.role)

    showMessage(successMessage, "success")

    if player then
        local executorCharacter = player.getCurrentCharacter()
        amb.print.info(("%s changed %s's role from '%s' to '%s'"):format(
            executorCharacter.getFullName(),
            targetName,
            oldRole,
            args.role
        ))
    else
        amb.print.info(("Console changed %s's role from '%s' to '%s'"):format(
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
            { name = "target", type = "player", help = "Player session ID" },
            { name = "role", type = "string", help = "Role name (user, admin, ambitioneer)" }
        }
    }
})