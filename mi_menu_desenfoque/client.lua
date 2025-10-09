-- =================================================================
-- ARCHIVO CLIENT.LUA: Lógica para enviar eventos a la UI
-- =================================================================

-- 1. Registrar un comando para abrir/cerrar el menú (Ejemplo simple)
local isMenuOpen = false

RegisterCommand('togglemenu', function()
    isMenuOpen = not isMenuOpen

    if isMenuOpen then
        -- Envía el mensaje 'openMenu' al JS
        SendNUIMessage({
            action = 'openMenu'
        })
        SetNuiFocus(true, true) -- Fija el foco en la UI
    else
        -- Envía el mensaje 'closeMenu' al JS
        SendNUIMessage({
            action = 'closeMenu'
        })
        SetNuiFocus(false, false) -- Regresa el foco al juego
    end
end)


-- 2. Ejemplo de cómo cambiar la intensidad del blur desde el juego
RegisterCommand('blurhigh', function()
    SendNUIMessage({
        action = 'setBlurLevel',
        level = '40px' -- Blur muy fuerte
    })
end)

RegisterCommand('blurlow', function()
    SendNUIMessage({
        action = 'setBlurLevel',
        level = '5px' -- Blur ligero
    })
end)
