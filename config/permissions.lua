permissionsConfig = {
    user = {
        label = 'User',
        inherits = {},
        permissions = {}
    },
    admin = {
        label = 'Administrator',
        inherits = {'user'},
        permissions = {
            'admin.getCoords',
            'admin.kick',
            'admin.giveItem'
        }
    },
    ambitioneer = {
        label = 'Ambitioneer',
        inherits = {'admin'},
        permissions = {
            'ambitioneer.ban',
            'ambitioneer.setRole',
            'ambitioneer.testNeed'
        }
    }
}