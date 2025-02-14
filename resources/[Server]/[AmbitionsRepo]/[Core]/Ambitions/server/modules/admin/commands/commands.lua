local debug = import('config.shared.config_debug')

ABT.RegisterCommand('setgroup', 'setGroup', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local group = args.group

    if not group then
        ABT.Print.Log(4, 'Group is required.')
        return
    end

    if group == 'superadmin' then
        group = 'admin'
        ABT.Print.Log(4, 'Group superadmin is not allowed, set to admin.')
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()
    character.setGroup(group)

    if debug.Commands.DebugSetGroup then
        ABT.Print.Log(2, ('Group %s set for player %s'):format(group, character.getCharacterId()))
    end
end, true, {
    help = "Set the group of a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to set the group for (ID or 'me')" },
        { name = "group", type = "string", help = "The group to assign to the player" }
    }
})


ABT.RegisterCommand('addaccountmoney', 'addMoneyToAccount', function(amberPlayer, args)
    if not args.account then
        ABT.Print.Log(3, 'Account is required.')
        return
    end

    if not args.amount then
        ABT.Print.Log(3, 'Amount is required.')
        return
    end

    local balance = amberPlayer.getCurrentCharacter().accounts.addAccountMoney(args.account, args.amount)

    if debug.Commands.DebugMoney then
        ABT.Print.Log(2, ('Added %s to account %s, new balance: %s'):format(args.amount, args.account, balance))
    end
end, false, {
    help = "Add money to an account",
    validate = true,
    args = {
        { name = "account", type = "string", help = "The account to add money to" },
        { name = "amount", type = "number", help = "The amount of money to add" }
    }
})

ABT.RegisterCommand('removeaccountmoney', 'removeMoneyFromAccount', function(amberPlayer, args)
    if not args.account then
        ABT.Print.Log(3, 'Account is required.')
        return
    end

    if not args.amount then
        ABT.Print.Log(3, 'Amount is required.')
        return
    end

    local balance = amberPlayer.getCurrentCharacter().accounts.removeAccountMoney(args.account, args.amount)

    if debug.Commands.DebugMoney then
        ABT.Print.Log(2, ('Removed %s to account %s, new balance: %s'):format(args.amount, args.account, balance))
    end
end, false, {
    help = "Remove money to an account",
    validate = true,
    args = {
        { name = "account", type = "string", help = "The account to remove money from" },
        { name = "amount", type = "number", help = "The amount of money to remove" }
    }
})

ABT.RegisterCommand('setaccountmoney', 'setMoneyToAccount', function(amberPlayer, args)
    if not args.account then
        ABT.Print.Log(3, 'Account is required.')
        return
    end

    if not args.amount then
        ABT.Print.Log(3, 'Amount is required.')
        return
    end

    local balance = amberPlayer.getCurrentCharacter().accounts.setAccountMoney(args.account, args.amount)

    if debug.Commands.DebugMoney then
        ABT.Print.Log(2, ('Set %s to account %s, new balance: %s'):format(args.amount, args.account, balance))
    end
end, false, {
    help = "set money to an account",
    validate = true,
    args = {
        { name = "account", type = "string", help = "The account to set money to" },
        { name = "amount", type = "number", help = "The amount of money to set" }
    }
})

ABT.RegisterCommand('setneed', 'setNeeds', function(amberPlayer, args)
    if not args.need then
        ABT.Print.Log(3, 'Need is required.')
        return
    end

    if not args.value then
        ABT.Print.Log(3, 'Value is required.')
        return
    end

    amberPlayer.getCurrentCharacter().needs.setNeed(args.need, args.value)

    if debug.Commands.DebugNeeds then
        ABT.Print.Log(2, ('Set %s to %s'):format(args.need, args.value))
    end
end, false, {
    help = "Set a need",
    validate = true,
    args = {
        { name = "need", type = "string", help = "The need to set" },
        { name = "value", type = "number", help = "The value to set the need to" }
    }
})

ABT.RegisterCommand('addneed', 'addNeeds', function(amberPlayer, args)
    if not args.need then
        ABT.Print.Log(3, 'Need is required.')
        return
    end

    if not args.amount then
        ABT.Print.Log(3, 'Amount is required.')
        return
    end

    amberPlayer.getCurrentCharacter().needs.modifyNeed(args.need, args.amount)

    if debug.Commands.DebugNeeds then
        ABT.Print.Log(2, ('Added %s to %s'):format(args.amount, args.need))
    end
end, false, {
    help = "Add to a need",
    validate = true,
    args = {
        { name = "need", type = "string", help = "The need to add to" },
        { name = "amount", type = "number", help = "The amount to add to the need" }
    }
})

ABT.RegisterCommand('removeneed', 'removeNeeds', function(amberPlayer, args)
    if not args.need then
        ABT.Print.Log(3, 'Need is required.')
        return
    end

    if not args.amount then
        ABT.Print.Log(3, 'Amount is required.')
        return
    end

    amberPlayer.getCurrentCharacter().needs.modifyNeed(args.need, -args.amount)

    if debug.Commands.DebugNeeds then
        ABT.Print.Log(2, ('Removed %s from %s'):format(args.amount, args.need))
    end
end, false, {
    help = "Remove from a need",
    validate = true,
    args = {
        { name = "need", type = "string", help = "The need to remove from" },
        { name = "amount", type = "number", help = "The amount to remove from the need" }
    }
})

ABT.RegisterCommand('getneeds', 'getNeeds', function(amberPlayer)
    local needs = amberPlayer.getCurrentCharacter().needs.getAllNeeds()

    ABT.Print.Log(2, 'Needs:', needs)
end, false, {
    help = "Get all needs"
})

ABT.RegisterCommand('heal', 'healCharacter', function(amberPlayer, args)
    local target = args.playerId or amberPlayer

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    target.getCurrentCharacter().needs.setNeed('hunger', 100)
    target.getCurrentCharacter().needs.setNeed('thirst', 100)
    target.getCurrentCharacter().needs.setNeed('stress', 0)

    target.getCurrentCharacter().triggerEvent('ambitions:command:healPlayer')
end, true, {
    help = "Heal a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to heal (ID or 'me')" }
    }
})

ABT.RegisterCommand('kill', 'killCharacter', function(amberPlayer, args)
    local target = args.playerId or amberPlayer

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    target.getCurrentCharacter().setHealth(0)
    target.getCurrentCharacter().setDeathState(1)

    target.getCurrentCharacter().triggerEvent('ambitions:command:killPlayer')
end, true, {
    help = "Kill a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to kill (ID or 'me')" }
    }
})

ABT.RegisterCommand('revive', 'reviveCharacter', function(amberPlayer, args)
    local target = args.playerId or amberPlayer

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    target.getCurrentCharacter().setHealth(200)
    target.getCurrentCharacter().setDeathState(0)
    target.getCurrentCharacter().needs.initializeNeeds()
    target.getCurrentCharacter().triggerEvent('ambitions:command:revivePlayer')
end, true, {
    help = "Revive a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to revive (ID or 'me')" }
    }
})

ABT.RegisterCommand('info', 'Info', function(amberPlayer)
    ABT.Print.Log(1, 'ID :', amberPlayer.source, '| Name : ', ABT.Player.GetPlayerIdentifier(amberPlayer.source).name, '| Group :', amberPlayer.getCurrentCharacter().getGroup(), '| Job :', amberPlayer.getCurrentCharacter().getJob().label, '| Job Grade :', amberPlayer.getCurrentCharacter().getJobGrade(), '| Crew :', amberPlayer.getCurrentCharacter().getCrew().label, '| Crew Grade :', amberPlayer.getCurrentCharacter().getCrewGrade())
end, false, {
    help = "Get your information"
})

ABT.RegisterCommand('data', 'Data', function(amberPlayer)
    local character = amberPlayer.getCurrentCharacter()

    character.triggerEvent('ambitions:test:showData')
end,false,{
    help = "Show data"
})

ABT.RegisterCommand('setjob', 'setJob', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local job = args.job
    local grade = args.grade

    if not job then
        ABT.Print.Log(3, 'Job is required.')
        return
    end

    if not grade then
        ABT.Print.Log(3, 'Grade is required.')
        return
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()
    character.setJob(job, grade)
end, true, {
    help = "Set the job of a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to set the job for (ID or 'me')" },
        { name = "job", type = "string", help = "The job to assign to the player" },
        { name = "grade", type = "string", help = "The grade to assign to the player" }
    }
})

ABT.RegisterCommand('setcrew', 'setCrew', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local crew = args.crew
    local grade = args.grade

    if not crew then
        ABT.Print.Log(3, 'Job is required.')
        return
    end

    if not grade then
        ABT.Print.Log(3, 'Grade is required.')
        return
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()
    character.setCrew(crew, grade)
end, true, {
    help = "Set the crew of a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to set the job for (ID or 'me')" },
        { name = "crew", type = "string", help = "The crew to assign to the player" },
        { name = "grade", type = "string", help = "The grade to assign to the player" }
    }
})

ABT.RegisterCommand('addlicense', 'addLicense', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local license = args.license

    if not license then
        ABT.Print.Log(3, 'License is required.')
        return
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()

    if character.hasLicense(license) then
        ABT.Print.Log(3, ('Player already has license %s.'):format(license))
        return
    end

    character.grantLicense(license, {})

    if debug.Commands.DebugLicenses then
        ABT.Print.Log(2, ('License %s added to player %s.'):format(license, character.getCharacterId()))
    end
end, true, {
    help = "Add a license to a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to add the license to (ID or 'me')" },
        { name = "license", type = "string", help = "The license to add" }
    }
})

ABT.RegisterCommand('revokelicense', 'revokeLicense', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local license = args.license

    if not license then
        ABT.Print.Log(3, 'License is required.')
        return
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()

    if not character.hasLicense(license) then
        ABT.Print.Log(3, ('Player does not have license %s.'):format(license))
        return
    end

    character.revokeLicense(license)

    if debug.Commands.DebugLicenses then
        ABT.Print.Log(2, ('License %s revoked from player %s.'):format(license, character.getCharacterId()))
    end
end, true, {
    help = "Revoke a license from a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to revoke the license from (ID or 'me')" },
        { name = "license", type = "string", help = "The license to revoke" }
    }
})

ABT.RegisterCommand('removelicense', 'removeLicense', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local license = args.license

    if not license then
        ABT.Print.Log(3, 'License is required.')
        return
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()

    if not character.hasLicense(license) then
        ABT.Print.Log(3, ('Player does not have license %s.'):format(license))
        return
    end

    character.removeLicense(license)

    if debug.Commands.DebugLicenses then
        ABT.Print.Log(2, ('License %s revoked from player %s.'):format(license, character.getCharacterId()))
    end
end, true, {
    help = "Remove a license from a player",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to remove the license from (ID or 'me')" },
        { name = "license", type = "string", help = "The license to remove" }
    }
})

ABT.RegisterCommand('haslicense', 'hasLicense', function(amberPlayer, args)
    local target = args.playerId or amberPlayer
    local license = args.license

    if not license then
        ABT.Print.Log(3, 'License is required.')
        return
    end

    if not target or not target.getCurrentCharacter() then
        ABT.Print.Log(3, 'Invalid target player or character.')
        return
    end

    local character = target.getCurrentCharacter()

    if character.hasLicense(license) then
        ABT.Print.Log(2, ('Player has license %s.'):format(license))
    else
        ABT.Print.Log(2, ('Player does not have license %s.'):format(license))
    end
end, true, {
    help = "Check if a player has a license",
    validate = true,
    args = {
        { name = "playerId", type = "player", help = "The player to check the license for (ID or 'me')" },
        { name = "license", type = "string", help = "The license to check" }
    }
})