--- Get player coordinates command
amb.RegisterCommand("getcoords", "admin.getCoords", function(player, args, showMessage)
    if not player then
        return showMessage("This command cannot be used from console")
    end

    local character = player.getCurrentCharacter()
    if not character then
        return showMessage("You need to have an active character", "error")
    end

    local coords = character.getPosition(true, true)
    local coordsString = ("vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, coords.w)

    showMessage(("Coordinates: %s"):format(coordsString), "info")

    amb.print.info(("%s used /getcoords at %s"):format(
        character.getFullName(),
        coordsString
    ))
end, {
    suggestion = {
        help = "Get your current coordinates"
    }
})