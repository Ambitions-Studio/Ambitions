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