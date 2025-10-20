-- =================================================================
-- CLIENT.LUA - VERSIÓN MEJORADA CON SISTEMAS AUTÓNOMOS
-- =================================================================

-- Variables Globales
local ESX = nil
local isMenuOpen = false
local isDayModeActive = false
local currentSpeedMult = 1.0
local playerData = {}

-- NUEVO: Variables para Sistemas Autónomos
local economicMarkets = {}
local activeEvents = {}
local playerStats = {
    menuOpens = 0,
    actionsPerformed = 0,
    playersTeleported = 0,
    chatMessagesSent = 0,
    lastAction = nil
}

-- Inicialización ESX
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) 
            ESX = obj 
        end)
        Citizen.Wait(100)
    end
    
    playerData = ESX.GetPlayerData()
    
    -- NUEVO: Inicializar sistemas autónomos
    InitializeEconomicSystem()
    StartEventScheduler()
    LoadPlayerStats()
    
    if Config.Debug then
        print('^2[MENU-ESX]^7 Sistema inicializado - Jugador: ' .. (playerData.name or 'Desconocido'))
        print('^2[MENU-ESX]^7 Sistemas autónomos cargados: Economía, Eventos, Estadísticas')
    end
end)

-- =================================================================
-- NUEVO: SISTEMA ECONÓMICO AUTÓNOMO
-- =================================================================

function InitializeEconomicSystem()
    if not Config.Economy.EnableDynamicMarkets then return end
    
    economicMarkets = {}
    
    for marketName, config in pairs(Config.Economy.DefaultMarkets) do
        economicMarkets[marketName] = {
            nombre = marketName,
            precioActual = config.precio,
            precioBase = config.precio,
            volatilidad = config.volatilidad,
            historial = {config.precio},
            tendencia = "estable",
            ultimaActualizacion = GetGameTimer()
        }
    end
    
    -- Programar actualizaciones de mercado
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.Economy.MarketUpdateInterval)
            UpdateEconomicMarkets()
        end
    end)
    
    if Config.Debug then
        print('^3[MENU-ESX]^7 Sistema económico inicializado con ' .. CountTable(economicMarkets) .. ' mercados')
    end
end

function UpdateEconomicMarkets()
    for marketName, market in pairs(economicMarkets) do
        local cambio = (math.random() - 0.5) * 2 * market.volatilidad
        local nuevoPrecio = math.max(market.precioBase * 0.5, market.precioActual * (1 + cambio))
        
        market.precioActual = math.floor(nuevoPrecio)
        table.insert(market.historial, market.precioActual)
        
        -- Mantener solo últimos 10 registros
        if #market.historial > 10 then
            table.remove(market.historial, 1)
        end
        
        -- Calcular tendencia
        market.tendencia = CalculateMarketTrend(market.historial)
        market.ultimaActualizacion = GetGameTimer()
    end
    
    if Config.Debug then
        print('^3[MENU-ESX]^7 Mercados económicos actualizados')
    end
end

function CalculateMarketTrend(historial)
    if #historial < 2 then return "estable" end
    
    local ultimo = historial[#historial]
    local anterior = historial[#historial - 1]
    local cambio = ((ultimo - anterior) / anterior) * 100
    
    if cambio > 2 then return "alcista" end
    if cambio < -2 then return "bajista" end
    return "estable"
end

function GetEconomicState()
    return {
        mercados = economicMarkets,
        ultimaActualizacion = GetGameTimer(),
        estadoGeneral = CalculateGeneralMarketState()
    }
end

function CalculateGeneralMarketState()
    local tendencias = {}
    for _, market in pairs(economicMarkets) do
        table.insert(tendencias, market.tendencia)
    end
    
    local alcistas = CountInTable(tendencias, "alcista")
    local bajistas = CountInTable(tendencias, "bajista")
    
    if alcistas > bajistas then return "positivo" end
    if bajistas > alcistas then return "negativo" end
    return "neutral"
end

-- =================================================================
-- NUEVO: SISTEMA DE EVENTOS AUTÓNOMO
-- =================================================================

function StartEventScheduler()
    if not Config.Events.EnableRandomEvents then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.Events.EventCheckInterval)
            
            if math.random() < Config.Events.EventProbability then
                TriggerRandomEvent()
            end
        end
    end)
end

function TriggerRandomEvent()
    local eventType = Config.Events.AvailableEvents[math.random(1, #Config.Events.AvailableEvents)]
    
    if eventType == "boom_immobiliario" then
        ESX.ShowNotification('~g~🏠 BOOM INMOBILIARIO: Precios de propiedades +20%!')
        economicMarkets.propiedades.precioActual = math.floor(economicMarkets.propiedades.precioActual * 1.2)
        
    elseif eventType == "crisis_combustible" then
        ESX.ShowNotification('~r~⛽ CRISIS COMBUSTIBLE: Precios de vehículos +15%!')
        economicMarkets.vehiculos.precioActual = math.floor(economicMarkets.vehiculos.precioActual * 1.15)
        
    elseif eventType == "tecnologia_avance" then
        ESX.ShowNotification('~b~💻 AVANCE TECNOLÓGICO: Recursos más accesibles!')
        economicMarkets.recursos.precioActual = math.floor(economicMarkets.recursos.precioActual * 0.9)
        
    elseif eventType == "mercado_estable" then
        ESX.ShowNotification('~y~📊 MERCADO ESTABLE: Precios normalizados!')
        -- Resetear a precios base
        for _, market in pairs(economicMarkets) do
            market.precioActual = market.precioBase
        end
    end
    
    -- Registrar evento activo
    activeEvents[GetGameTimer()] = {
        tipo = eventType,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    -- Notificar a la interfaz si el menú está abierto
    if isMenuOpen then
        SendNUIMessage({
            action = 'notificarEvento',
            evento = {
                tipo = eventType,
                mensaje = 'Evento económico activado',
                timestamp = os.date('%H:%M:%S')
            }
        })
    end
    
    if Config.Debug then
        print('^4[MENU-ESX]^7 Evento activado: ' .. eventType)
    end
end

-- =================================================================
-- NUEVO: SISTEMA DE ESTADÍSTICAS
-- =================================================================

function LoadPlayerStats()
    -- En un sistema real, cargaría de una base de datos
    -- Por ahora inicializamos vacío
    playerStats = {
        menuOpens = 0,
        actionsPerformed = 0,
        playersTeleported = 0,
        chatMessagesSent = 0,
        lastAction = nil,
        firstUse = os.date('%Y-%m-%d %H:%M:%S')
    }
end

function SavePlayerStats()
    -- En un sistema real, guardaría en base de datos
    -- Por ahora solo mostramos en debug
    if Config.Debug then
        print('^5[MENU-ESX]^7 Estadísticas guardadas:')
        PrintTable(playerStats)
    end
end

function RegisterStatAction(actionType)
    playerStats.actionsPerformed = playerStats.actionsPerformed + 1
    playerStats.lastAction = {
        tipo = actionType,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    if actionType == "teleport" then
        playerStats.playersTeleported = playerStats.playersTeleported + 1
    elseif actionType == "chat" then
        playerStats.chatMessagesSent = playerStats.chatMessagesSent + 1
    end
end

-- =================================================================
-- FUNCIONES PRINCIPALES (ORIGINALES MEJORADAS)
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
    
    -- NUEVO: Registrar estadística
    playerStats.menuOpens = playerStats.menuOpens + 1
    
    playerData = ESX.GetPlayerData()
    
    -- NUEVO: Enviar datos económicos a la interfaz
    local economicState = GetEconomicState()
    local activeEventsList = {}
    for timestamp, event in pairs(activeEvents) do
        table.insert(activeEventsList, event)
    end
    
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
        },
        -- NUEVO: Datos de sistemas autónomos
        economicData = economicState,
        activeEvents = activeEventsList,
        playerStats = playerStats
    })
    
    if Config.Blur.Enabled then
        SendNUIMessage({
            action = 'enableBlur',
            level = Config.Blur.DefaultStrength
        })
    end
    
    if Config.Debug then
        print('^2[MENU-ESX]^7 Menú abierto - Stats: ' .. playerStats.menuOpens .. ' aperturas')
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
    
    -- NUEVO: Guardar estadísticas al cerrar
    SavePlayerStats()
    
    SendNUIMessage({ action = 'closeMenu' })
end

-- =================================================================
-- CALLBACKS NUI (ORIGINALES MEJORADOS)
-- =================================================================

RegisterNUICallback('callAction', function(data, cb)
    local action = data.action
    local payload = data.payload or {}
    
    if Config.Debug then
        print('^3[MENU-ESX]^7 Acción recibida: ' .. action)
    end
    
    -- NUEVO: Registrar estadística de acción
    RegisterStatAction(action)
    
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
            
        -- NUEVO: Acciones para sistemas autónomos
        elseif action == 'get_economic_data' then
            local economicState = GetEconomicState()
            SendNUIMessage({
                action = 'updateEconomicData',
                data = economicState
            })
            
        elseif action == 'get_player_stats' then
            SendNUIMessage({
                action = 'updatePlayerStats', 
                stats = playerStats
            })
            
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

-- [El resto del código permanece igual...]

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
-- FUNCIONES UTILITARIAS (ORIGINALES + NUEVAS)
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

-- NUEVO: Funciones utilitarias para tablas
function CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

function CountInTable(tbl, value)
    local count = 0
    for _, v in pairs(tbl) do
        if v == value then count = count + 1 end
    end
    return count
end

function PrintTable(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            PrintTable(v, indent + 1)
        else
            print(formatting .. tostring(v))
        end
    end
end

-- =================================================================
-- COMANDOS Y EVENTOS (ORIGINALES)
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
        
        -- NUEVO: Guardar estadísticas al detener recurso
        SavePlayerStats()
    end
end)

print('^2[MENU-ESX]^7 Cliente cargado - Presiona ' .. Config.MenuKey .. ' para abrir menú')
print('^2[MENU-ESX]^7 Sistemas autónomos: Economía, Eventos, Estadísticas')