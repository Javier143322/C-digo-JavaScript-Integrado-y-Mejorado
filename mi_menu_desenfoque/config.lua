Config = {}

-- Sistema Principal
Config.Debug = true
Config.MenuKey = "F5"
Config.EnableBlurEffect = true

-- Configuración ESX
Config.ESX = {
    UseESX = true,
    NotificationStyle = "esx"
}

-- Sistema de Menú
Config.Menu = {
    DefaultPosition = { x = "50%", y = "50%" },
    EnableDragging = true,
    SavePosition = true,
    AnimationDuration = 300
}

-- Efectos Visuales
Config.Blur = {
    Enabled = true,
    DefaultStrength = "15px",
    Levels = {
        low = "5px",
        medium = "15px", 
        high = "30px"
    }
}

-- Sistema de Jugadores
Config.Players = {
    MaxDistance = 100.0,
    UpdateInterval = 3000,
    ShowPing = true,
    ShowDistance = true
}

-- Control de Velocidad
Config.Speed = {
    MinMultiplier = 0.1,
    MaxMultiplier = 5.0,
    DefaultMultiplier = 1.0
}

-- Notificaciones
Config.Notifications = {
    Duration = 5000,
    Position = "top-right",
    MaxNotifications = 5
}

-- NUEVO: Sistema Económico Autónomo
Config.Economy = {
    EnableDynamicMarkets = true,
    MarketUpdateInterval = 120000, -- 2 minutos
    DefaultMarkets = {
        propiedades = { precio = 150000, volatilidad = 0.04 },
        vehiculos = { precio = 35000, volatilidad = 0.06 },
        armas = { precio = 8000, volatilidad = 0.10 },
        recursos = { precio = 1500, volatilidad = 0.12 }
    }
}

-- NUEVO: Sistema de Eventos Autónomo
Config.Events = {
    EnableRandomEvents = true,
    EventCheckInterval = 60000, -- 1 minuto
    EventProbability = 0.05, -- 5% de chance
    AvailableEvents = {
        "boom_immobiliario",
        "crisis_combustible", 
        "tecnologia_avance",
        "mercado_estable"
    }
}

-- NUEVO: Sistema de Estadísticas
Config.Statistics = {
    TrackUsage = true,
    SaveInterval = 300000, -- 5 minutos
    MaxLogEntries = 1000
}