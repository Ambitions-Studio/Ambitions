fx_version 'cerulean'

game 'gta5'

use_experimental_fxv2_oal 'yes'

author 'Ambitions Studio'

description 'Ambitions — A modern, scalable, and secure FiveM framework built with Lua 5.4 standards. Designed for performance, modularity, and full open-source collaboration.'

version '0.0.0'

name 'Ambitions'

lua54 'yes'

shared_script 'importation.lua'

shared_scripts {
    'shared/initExports.lua',

    'shared/lib/print/log.lua',

    'translations/*.lua',

    'config/shared/*.lua',
    'shared/lib/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/initExports.lua',

    'config/server/*.lua',
    'server/lib/**/*.lua',
}

client_scripts {
    'client/lib/**/*.lua',
}

files {
    'init.lua',
    'importation.lua',
}

dependencies {
    'oxmysql'
}