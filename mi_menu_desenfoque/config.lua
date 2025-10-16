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