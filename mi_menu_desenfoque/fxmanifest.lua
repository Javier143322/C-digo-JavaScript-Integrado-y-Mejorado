
fx_version 'cerulean'
game 'gta5'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css', -- Si lo incluiste en la mejora anterior
    'html/app.js',
}

-- ¡NUEVO! Carga el script Lua para la lógica del juego
client_scripts {
    'client.lua'
}

