fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Custom Vorhang Script für New Life City'
version '1.0.0'
author 'XenoKeks || FreeTime Scripts'

dependencies {
    'ox_lib',
    'es_extended'
}

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'shared/config.lua'
}

client_scripts {
    'client/ui.lua',
    'client/main.lua'
}

server_scripts {
    '@ox_mysql/lib/MySQL.lua',
    'server/discord.lua',
    'server/main.lua'
}
