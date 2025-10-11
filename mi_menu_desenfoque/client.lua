-- =================================================================
-- ARCHIVO CLIENT.LUA: Lógica Principal y de Comunicación
-- =================================================================

-- Variable de estado global para controlar el menú
local isMenuOpen = false
local isDayModeActive = false 
local currentSpeedMult = 1.0 

-- =================================================================
-- FUNCIONES CENTRALES DE ENTRADA/SALIDA DE MENÚ
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
-- HILO PRINCIPAL: COMANDOS Y TECLA ESC (OPTIMIZADO)
-- =================================================================

-- 1. Comando /togglemenu
RegisterCommand('togglemenu', function()
    if isMenuOpen then
        closeMenu()
    else
        openMenu()
    end
end)

-- 2. Tecla ESC (Optimizado con Wait(5))
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5) 

        if IsNuiFocused() and IsControlJustReleased(0, 322) then 
            if isMenuOpen then
                closeMenu()
            end
        end
    end
end)

-- 3. Comandos de ejemplo para cambiar el Blur
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
    isDayModeActive = data.estado 
    
    if isDayModeActive then
        Citizen.CreateThread(function()
            while isDayModeActive do
                Citizen.Wait(0) 
                NetworkOverrideClockTime(12, 0, 0)
            end
            ClearOverrideClockTime()
        end)
        notifyUI('Modo Siempre Día ACTIVADO.', 'success') 
    else
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
        currentSpeedMult = velocidadFinal
        local factorVelocidad = velocidadFinal * 1.5
        
        SetRunSpeedMult(playerPed, factorVelocidad)
        SetMoveSpeedMultiplier(playerPed, factorVelocidad)

        notifyUI('Velocidad ajustada a ' .. string.format("%.1f", velocidadFinal), 'success')
    end
    
    cb('ok')
end)

-- CALLBACK: LISTA DINÁMICA DE JUGADORES (FINAL: Recolección de datos con filtro de proximidad)
RegisterNuiCallbackType('request_player_data')
AddEventHandler('__cfx_nui:request_player_data', function(data, cb)
    local playersTable = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local maxDistance = 100.0 -- FILTRO: Jugadores en un radio de 100 metros

    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        
        -- Evita el jugador local
        if ped ~= 0 and playerId ~= PlayerId() then 
            local targetCoords = GetEntityCoords(ped)
            
            -- CÁLCULO DE DISTANCIA
            local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, true)
            
            if distance <= maxDistance then
                local playerName = GetPlayerName(playerId)
                local playerPing = GetPlayerPing(playerId)
                
                table.insert(playersTable, {
                    id = playerId,
                    name = playerName,
                    ping = playerPing,
                    distance = math.floor(distance) -- Distancia redondeada para mostrar en la UI
                })
            end
        end
    end
    
    SendNUIMessage({
        action = 'renderPlayerList', 
        data = playersTable
    })
    
    cb('ok') 
end)

-- CALLBACK: TELETRANSPORTE AL JUGADOR (NUEVA FUNCIÓN)
RegisterNuiCallbackType('teleport_to_player')
AddEventHandler('__cfx_nui:teleport_to_player', function(data, cb)
    local targetId = data.targetId
    local targetPed = GetPlayerPed(targetId)
    
    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        
        -- Ajuste de coordenadas para evitar caer en el suelo
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.5, false, false, false, true)
        
        notifyUI('Teletransporte exitoso.', 'success')
    else
        notifyUI('ERROR: Jugador no encontrado o fuera de rango.', 'error')
    end
    
    cb('ok')
end)

-- HANDLER DE READY 
RegisterNuiCallbackType('uiReady')
AddEventHandler('__cfx_nui:uiReady', function(data, cb)
    print('----------------------------------------------------')
    print('¡UI de FiveM cargada y lista para comunicación!')
    print('----------------------------------------------------')
    cb('ok')
end)

-- =================================================================
-- NUEVO CALLBACK: SINCRONIZACIÓN DE ESTADO INICIAL (FINAL)
-- =================================================================

RegisterNuiCallbackType('request_initial_state')
AddEventHandler('__cfx_nui:request_initial_state', function(data, cb)
    -- Envía el estado actual del toggle 'Siempre Día' a la UI
    SendNUIMessage({
        action = 'updateToggleState',
        toggleName = 'siempre_dia',
        estado = isDayModeActive -- La variable global definida al inicio de client.lua
    })
    cb('ok')
end)
