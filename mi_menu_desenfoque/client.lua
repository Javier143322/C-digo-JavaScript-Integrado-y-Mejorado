-- =================================================================
-- ARCHIVO CLIENT.LUA: Lógica Principal y de Comunicación
-- =================================================================

-- Variable de estado global para controlar el menú
local isMenuOpen = false
local isDayModeActive = false -- Variable para el toggle de Siempre Día
local currentSpeedMult = 1.0 -- Velocidad base del jugador

-- =================================================================
-- FUNCIONES CENTRALES DE ENTRADA/SALIDA DE MENÚ (LIMPIO Y ÚNICO)
-- =================================================================

local function openMenu()
    SendNUIMessage({ action = 'openMenu' })
    SetNuiFocus(true, true)
    isMenuOpen = true
end

local function closeMenu()
    SendNUIMessage({ action = 'closeMenu' })
    SetNuiFocus(false, false)
    isMenuOpen = false
end

-- =================================================================
-- FUNCIÓN CENTRAL PARA NOTIFICAR A LA UI
-- =================================================================

local function notifyUI(message, type)
    SendNUIMessage({
        action = 'showNotification',
        message = message,
        type = type or 'success'
    })
end

-- =================================================================
-- HILO PRINCIPAL: COMANDOS Y TECLA ESC
-- =================================================================

-- 1. Comando /togglemenu
RegisterCommand('togglemenu', function()
    if isMenuOpen then
        closeMenu()
    else
        openMenu()
    end
end)

-- 2. Tecla ESC (Se ejecuta continuamente en el juego)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) 

        -- Si el foco está en la UI (menú potencialmente abierto) Y se presiona ESC (tecla 322)
        if IsNuiFocused() and IsControlJustReleased(0, 322) then 
            if isMenuOpen then
                closeMenu()
            end
        end
    end
end)

-- 3. Comandos de ejemplo para cambiar el Blur (funcionalidad de la app.js)
RegisterCommand('blurhigh', function()
    SendNUIMessage({
        action = 'setBlurLevel',
        level = '40px'
    })
    notifyUI('Blur ajustado a nivel ALTO.', 'success')
end)

RegisterCommand('blurlow', function()
    SendNUIMessage({
        action = 'setBlurLevel',
        level = '5px'
    })
    notifyUI('Blur ajustado a nivel BAJO.', 'success')
end)

-- =================================================================
-- CALLBACKS DE LA UI (NUI CALLBACKS)
-- =================================================================

-- CALLBACK: Botón Hacer Algo
RegisterNuiCallbackType('ejecutar_accion_uno')
AddEventHandler('__cfx_nui:ejecutar_accion_uno', function(data, cb)
    Citizen.CreateThread(function()
        SetFlash(0, 0, 500, 500, 500)
    end)
    
    notifyUI('Acción de parpadeo ejecutada con éxito.', 'success') 
    cb('ok') 
end)

-- CALLBACK: Toggle de Siempre Día
RegisterNuiCallbackType('toggle_siempre_dia')
AddEventHandler('__cfx_nui:toggle_siempre_dia', function(data, cb)
    isDayModeActive = data.estado -- Actualizamos la variable de estado
    
    if isDayModeActive then
        -- Inicia el thread de loop SÓLO si está activado
        Citizen.CreateThread(function()
            while isDayModeActive do -- El loop usa la variable global
                Citizen.Wait(0)
                NetworkOverrideClockTime(12, 0, 0) -- Fija la hora a las 12:00
            end
            ClearOverrideClockTime() -- Limpia la hora cuando el loop termina
        end)
        notifyUI('Modo Siempre Día ACTIVADO.', 'success') 
    else
        -- Simplemente limpia si se desactiva (el thread anterior terminará solo)
        ClearOverrideClockTime()
        notifyUI('Modo Siempre Día DESACTIVADO.', 'error') 
    end
    
    cb('ok')
end)

-- CALLBACK: Input de Mensaje de Chat
RegisterNuiCallbackType('enviar_mensaje_chat')
AddEventHandler('__cfx_nui:enviar_mensaje_chat', function(data, cb)
    local mensaje = data.mensaje

    if mensaje and mensaje ~= '' then
        TriggerEvent('chat:addMessage', {
            color = { 255, 165, 0 }, 
            args = { 'MENÚ UI', 'ha enviado: ' .. mensaje }
        })
        notifyUI('Mensaje enviado al chat.', 'success')
    else
        notifyUI('ERROR: Mensaje vacío.', 'error')
    end
    
    cb('ok')
end)

-- CALLBACK: Slider de Velocidad
RegisterNuiCallbackType('ajustar_velocidad')
AddEventHandler('__cfx_nui:ajustar_velocidad', function(data, cb)
    local velocidadFinal = data.velocidad 
    local playerPed = PlayerPedId()

    if velocidadFinal then
        currentSpeedMult = velocidadFinal -- Guardamos el valor actual
        local factorVelocidad = velocidadFinal * 1.5
        
        SetRunSpeedMult(playerPed, factorVelocidad)
        SetMoveSpeedMultiplier(playerPed, factorVelocidad)

        notifyUI('Velocidad ajustada a ' .. string.format("%.1f", velocidadFinal), 'success')
    end
    
    cb('ok')
end)

-- =================================================================
-- CÓDIGO FINAL: LISTA DINÁMICA DE JUGADORES (Incompleto)
-- =================================================================

RegisterNuiCallbackType('request_player_data')
AddEventHandler('__cfx_nui:request_player_data', function(data, cb)
    local playersTable = {}
    
    -- SIMULACIÓN DE DATOS (PARA PRUEBA)
    for i = 1, 5 do
        table.insert(playersTable, {
            id = i,
            name = "Jugador de Prueba " .. i,
            ping = math.random(30, 100)
        })
    end
    
    -- Envía la lista al JS para que la dibuje
    SendNUIMessage({
        action = 'renderPlayerList', 
        data = playersTable
    })
    
    cb('ok') 
end)

-- =================================================================
-- HANDLER DE READY (Asegura que el menú esté listo antes de usarlo)
-- =================================================================

RegisterNuiCallbackType('uiReady')
AddEventHandler('__cfx_nui:uiReady', function(data, cb)
    print('----------------------------------------------------')
    print('¡UI de FiveM cargada y lista para comunicación!')
    print('----------------------------------------------------')
    cb('ok')
end)
