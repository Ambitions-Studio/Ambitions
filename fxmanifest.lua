fx_version 'cerulean'

game 'gta5'

use_experimental_fxv2_oal 'yes'

author 'Ambitions Studio'

description 'Ambitions — A modern, scalable, and secure FiveM framework built with Lua 5.4 standards. Designed for performance, modularity, and full open-source collaboration.'

version '0.6.0'

name 'Ambitions'

lua54 'yes'

shared_scripts {
    'shared/init.lua',
    'shared/lib/callback/callback.lua'
}

server_script 'server/lib/callback/callback.lua'
client_script 'client/lib/callback/callback.lua'

shared_script {
    'shared/lib/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'config/migration.lua',
    'config/permissions.lua',

    'server/database/schema.lua',
    'server/database/sqlGenerator.lua',
    'server/database/connectionValidator.lua',
    'server/database/migration.lua',
    'server/database/permissionsSync.lua',
    'server/database/autoMigration.lua',

    'server/classes/*.lua',

    'server/lib/**/*.lua',

    'server/modules/**/*.lua',

    'server/init.lua'
}

client_scripts {
    -- 'client/lib/**/*.lua'
}

files {
    'init.lua',
}

dependencies {
    'oxmysql'
}