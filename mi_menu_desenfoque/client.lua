-- =================================================================
-- CLIENT.LUA - VERSIÓN FINAL MEJORADA PARA ESX
-- =================================================================

-- Variables Globales
local ESX = nil
local isMenuOpen = false
local isDayModeActive = false
local currentSpeedMult = 1.0
local playerData = {}

-- Inicialización ESX
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) 
            ESX = obj 
        end)
        Citizen.Wait(100)
    end
    
    playerData = ESX.GetPlayerData()
    
    if Config.Debug then
        print('^2[MENU-ESX]^7 Sistema inicializado - Jugador: ' .. (playerData.name or 'Desconocido'))
    end
end)

-- =================================================================
-- FUNCIONES PRINCIPALES
-- =================================================================

function OpenMenu()
    if isMenuOpen then return end
    
    if ESX == nil then
        print('^1[MENU-ESX]^7 Error: ESX no está cargado')
        return
    end
    
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    isMenuOpen = true
    
    playerData = ESX.GetPlayerData()
    
    SendNUIMessage({
        action = 'openMenu',
        playerData = {
            name = playerData.name or 'Jugador',
            money = playerData.money or 0,
            job = playerData.job?.label or 'Desempleado'
        },
        settings = {
            dayMode = isDayModeActive,
            speedMultiplier = currentSpeedMult
        }
    })
    
    if Config.Blur.Enabled then
        SendNUIMessage({
            action = 'enableBlur',
            level = Config.Blur.DefaultStrength
        })
    end
    
    if Config.Debug then
        print('^2[MENU-ESX]^7 Menú abierto')
    end
end

function CloseMenu()
    if not isMenuOpen then return end
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    isMenuOpen = false
    
    SendNUIMessage({ action = 'disableBlur' })
    
    if isDayModeActive then
        ClearOverrideClockTime()
        isDayModeActive = false
    end
    
    SendNUIMessage({ action = 'closeMenu' })
end

-- =================================================================
-- CALLBACKS NUI
-- =================================================================

RegisterNUICallback('callAction', function(data, cb)
    local action = data.action
    local payload = data.payload or {}
    
    if Config.Debug then
        print('^3[MENU-ESX]^7 Acción recibida: ' .. action)
    end
    
    local success, errorMsg = pcall(function()
        if action == 'ejecutar_accion_uno' then
            SetFlash(0, 0, 500, 500, 500)
            ESX.ShowNotification('~g~⚡ Acción ejecutada correctamente')
            
        elseif action == 'toggle_siempre_dia' then
            local newState = payload.estado
            isDayModeActive = newState
            
            if isDayModeActive then
                Citizen.CreateThread(function()
                    while isDayModeActive do
                        NetworkOverrideClockTime(12, 0, 0)
                        Citizen.Wait(1000)
                    end
                    ClearOverrideClockTime()
                end)
                ESX.ShowNotification('~y~☀️ Modo Siempre Día ACTIVADO')
            else
                ClearOverrideClockTime()
                ESX.ShowNotification('~r~🌙 Modo Siempre Día DESACTIVADO')
            end
            
        elseif action == 'enviar_mensaje_chat' then
            local mensaje = tostring(payload.mensaje or '')
            
            if mensaje:gsub("%s+", "") == "" then
                ESX.ShowNotification('~r~❌ El mensaje no puede estar vacío')
                return
            end
            
            TriggerEvent('chat:addMessage', {
                color = {255, 165, 0},
                args = {'[SISTEMA]', mensaje}
            })
            ESX.ShowNotification('~g~📤 Mensaje enviado al chat')
            
        elseif action == 'ajustar_velocidad' then
            local velocidad = tonumber(payload.velocidad) or 1.0
            velocidad = math.max(0.1, math.min(5.0, velocidad))
            
            currentSpeedMult = velocidad
            local playerPed = PlayerPedId()
            
            SetRunSprintMultiplierForPlayer(playerPed, velocidad * 1.5)
            SetSwimMultiplierForPlayer(playerPed, velocidad * 1.5)
            
            ESX.ShowNotification(string.format('~y~🚀 Velocidad ajustada a %.1fx', velocidad))
            
        elseif action == 'request_player_data' then
            local players = GetNearbyPlayers()
            
            SendNUIMessage({
                action = 'renderPlayerList',
                data = {
                    players = players,
                    total = #players
                }
            })
            
        elseif action == 'teleport_to_player' then
            local targetId = tonumber(payload.targetId)
            
            if not targetId then
                ESX.ShowNotification('~r~❌ ID de jugador inválido')
                return
            end
            
            local targetPed = GetPlayerPed(targetId)
            
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                SetEntityCoords(PlayerPedId(), targetCoords.x, targetCoords.y, targetCoords.z + 1.0, false, false, false, false)
                ESX.ShowNotification('~g~⚡ Teletransportado al jugador')
            else
                ESX.ShowNotification('~r~❌ Jugador no encontrado')
            end
            
        elseif action == 'set_blur_level' then
            local level = payload.level
            if level then
                SendNUIMessage({
                    action = 'setBlurLevel',
                    level = level
                })
            end
            
        else
            print('^3[MENU-ESX]^7 Acción no reconocida: ' .. tostring(action))
        end
    end)
    
    if not success then
        print('^1[MENU-ESX]^7 Error en callback: ' .. tostring(errorMsg))
        ESX.ShowNotification('~r~❌ Error ejecutando la acción')
    end
    
    cb('ok')
end)

RegisterNUICallback('uiReady', function(data, cb)
    if Config.Debug then
        print('^2[MENU-ESX]^7 Interfaz de usuario lista')
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    CloseMenu()
    cb('ok')
end)

-- =================================================================
-- FUNCIONES UTILITARIAS
-- =================================================================

function GetNearbyPlayers()
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, playerId in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerId)
        
        if targetPed ~= playerPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= Config.Players.MaxDistance then
                table.insert(players, {
                    id = playerId,
                    name = GetPlayerName(playerId),
                    ping = GetPlayerPing(playerId),
                    distance = math.floor(distance)
                })
            end
        end
    end
    
    table.sort(players, function(a, b)
        return a.distance < b.distance
    end)
    
    return players
end

-- =================================================================
-- COMANDOS Y EVENTOS
-- =================================================================

RegisterCommand('menudesenfoque', function()
    if isMenuOpen then
        CloseMenu()
    else
        OpenMenu()
    end
end, false)

RegisterKeyMapping('menudesenfoque', 'Abrir/Cerrar Menú', 'keyboard', Config.MenuKey)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 322) and isMenuOpen then
            CloseMenu()
        end
    end
end)

AddEventHandler('esx:onPlayerDeath', function()
    if isMenuOpen then
        CloseMenu()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then CloseMenu() end
        if isDayModeActive then ClearOverrideClockTime() end
        
        local playerPed = PlayerPedId()
        SetRunSprintMultiplierForPlayer(playerPed, 1.0)
        SetSwimMultiplierForPlayer(playerPed, 1.0)
    end
end)

print('^2[MENU-ESX]^7 Cliente cargado - Presiona ' .. Config.MenuKey .. ' para abrir menú')