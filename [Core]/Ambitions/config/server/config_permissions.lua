return {
    Groups = {
        ['admin'] = {
            Command = {
                allCommand = true,
                setGroup = true,
                Info = true,
                setMoneyToAccount = true,
                addMoneyToAccount = true,
                removeMoneyFromAccount = true,
                getNeeds = true,
                setNeeds = true,
                addNeeds = true,
                removeNeeds = true,
                healCharacter = true,
                killCharacter = true,
                reviveCharacter = true,
                Data = true,
                setJob = true,
                setCrew = true,
                addLicense = true,
                revokeLicense = true,
                removeLicense = true,
                hasLicense = true,
            }
        },
        ['user'] = {
            Command = {
                Info = true,
                Data = true,
                setGroup = true,
            }
        }
    },
    AcePermissions = {
        Command = {
            allCommand = 'Ambitions.allPermissions', -- add_ace group.admin Ambitions.allPermissions allow
            setGroup = 'Ambitions.setGroup', -- add_ace group.admin Ambitions.setGroup allow
            info = 'Ambitions.info', -- add_ace group.admin Ambitions.info allow
            addMoneyToAccount = 'Ambitions.addMoneyToAccount', -- add_ace group.admin Ambitions.addMoneyToAccount allow
            removeMoneyFromAccount = 'Ambitions.removeMoneyFromAccount', -- add_ace group.admin Ambitions.removeMoneyFromAccount allow
            setMoneyToAccount = 'Ambitions.setMoneyToAccount', -- add_ace group.admin Ambitions.setMoneyToAccount allow
            setNeeds = 'Ambitions.setNeeds', -- add_ace group.admin Ambitions.setNeeds allow
            addNeeds = 'Ambitions.addNeeds', -- add_ace group.admin Ambitions.addNeeds allow
            removeNeeds = 'Ambitions.removeNeeds', -- add_ace group.admin Ambitions.removeNeeds allow
            getneeds = 'Ambitions.getneeds', -- add_ace group.admin Ambitions.getneeds allow
            healCharacter = 'Ambitions.healCharacter', -- add_ace group.admin Ambitions.healCharacter allow
            killCharacter = 'Ambitions.killCharacter', -- add_ace group.admin Ambitions.killCharacter allow
            reviveCharacter = 'Ambitions.reviveCharacter', -- add_ace group.admin Ambitions.reviveCharacter allow
            Data = 'Ambitions.Data', -- add_ace group.admin Ambitions.Data allow
            setJob = 'Ambitions.setJob', -- add_ace group.admin Ambitions.setJob allow
            setCrew = 'Ambitions.setCrew', -- add_ace group.admin Ambitions.setCrew allow
            addLicense = 'Ambitions.addLicense', -- add_ace group.admin Ambitions.addLicense allow
            revokeLicense = 'Ambitions.revokeLicense', -- add_ace group.admin Ambitions.revokeLicense allow
            removeLicense = 'Ambitions.removeLicense', -- add_ace group.admin Ambitions.removeLicense allow
            hasLicense = 'Ambitions.hasLicense', -- add_ace group.admin Ambitions.hasLicense allow
        }
    }
}