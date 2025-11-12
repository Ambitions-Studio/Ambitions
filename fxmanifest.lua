fx_version 'cerulean'

game 'gta5'

use_experimental_fxv2_oal 'yes'

author 'Ambitions Studio'

description 'Ambitions — A modern, scalable, and secure FiveM framework built with Lua 5.4 standards. Designed for performance, modularity, and full open-source collaboration.'

version '0.6.0'

name 'Ambitions'

lua54 'yes'

shared_script 'importation.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/init.lua',
    'server/database/autoMigration.lua',
    'server/modules/core/savePlayer.lua',
}

client_scripts {
    'client/init.lua'
}

files {
    'verification.lua',
    'importation.lua',
    'client/**/*.lua',
    'shared/**/*.lua',
    'config/*.lua'
}

dependencies {
    'oxmysql'
}