fx_version 'cerulean'

game 'gta5'

author 'Primordial Studio'

description 'Ambitions Framework Handmade'

version '0.1.3'

name 'Ambitions'

lua54 'yes'

shared_script 'importation.lua'

server_script 'server/lib/callback/*.lua'
client_script 'client/lib/callback/*.lua'

shared_scripts {
    'shared/initExports.lua',

    'config/shared/*.lua',
    'config/*.lua',

    'shared/lib/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/classes/*.lua',

    'server/initExports.lua',

    'config/server/*.lua',

    'server/lib/**/*.lua',

    'server/modules/**/*.lua',
    'server/modules/admin/**/*.lua',

    'server/main.lua',
}

client_scripts {
    'client/initExports.lua',

    'config/client/*.lua',

    'client/lib/**/*.lua',

    'client/modules/events/*.lua',
    'client/modules/callback/*.lua',
    'client/modules/core/**/*.lua',
}

files {
    'init.lua',
    'importation.lua'
}

dependencies {
    'oxmysql',
}