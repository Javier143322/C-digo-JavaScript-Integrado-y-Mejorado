fx_version 'cerulean'
game 'gta5'

name 'mi_menú_desenfoque'
author 'TuNombre'
description 'Sistema de Menú NUI Avanzado con Efectos Blur - Compatible ESX'
version '2.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'config.lua'
}

client_scripts {
    'config.lua',
    'client.lua'
}

dependencies {
    'es_extended'
}

lua54 'yes'