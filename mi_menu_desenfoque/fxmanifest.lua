
fx_version 'bodacious' -- Versión moderna y compatible
games { 'gta5' }

-- Información del recurso (puedes cambiar 'mi_menú_desenfoque' al nombre de tu carpeta)
resource_type 'menu' { name = 'Menú NUI Glassmorphism' }

-- Archivo de interfaz de usuario
ui_page 'html/index.html'

-- Archivos que el navegador de la UI puede acceder
files {
    'html/index.html',
    'html/app.js',
    -- Si usaste CSS externo, descomenta la siguiente línea.
    -- 'html/style.css', 
}

-- Scripts del cliente (Lógica del juego)
client_scripts {
    'client.lua'
}
