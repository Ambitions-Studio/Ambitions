fx_version 'cerulean'

game 'gta5'

author 'Primordial Studio'

description 'Ambitions HUD for Ambitions Framework'

version '0.0.1'

name 'Ambitions Hud'

lua54 'yes'

shared_scripts {
    '@Ambitions/init.lua',
    'config/shared/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/*.lua',
}

client_scripts {
    'client/*.lua',
}

ui_page ''
files {
}

dependencies {
    'oxmysql',
    'Ambitions'
}