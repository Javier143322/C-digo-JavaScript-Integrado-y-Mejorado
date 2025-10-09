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
-- =================================================================
-- CÓDIGO AÑADIDO: CERRAR MENÚ CON TECLA ESC
-- =================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Espera mínima para optimización

        -- Si el menú está abierto (foco en la UI) Y presionamos ESC (tecla 322)
        if IsNuiFocused() and IsControlJustReleased(0, 322) then 
            
            -- Lógica para cerrar el menú (la misma que en el comando /togglemenu)
            SendNUIMessage({
                action = 'closeMenu'
            })
            SetNuiFocus(false, false)
            isMenuOpen = false -- Asegúrate de que tu variable de estado se actualice
        end
    end
end)
