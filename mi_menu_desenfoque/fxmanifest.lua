fx_version 'bodacious' -- Versión moderna
games { 'gta5' }

-- Información del recurso (puedes cambiar 'mi_menú_desenfoque' al nombre de tu carpeta)
resource_type 'menu' { name = 'Menú NUI Glassmorphism' }

-- Archivo de interfaz de usuario
ui_page 'html/index.html'

-- Archivos que el navegador de la UI puede acceder (AHORA INCLUYE style.css)
files {
    'html/index.html',
    'html/app.js',
    'html/style.css', 
}

-- Scripts del cliente (Lógica del juego)
client_scripts {
    'client.lua'
}
