// =================================================================
// APP.JS - VERSIÓN MEJORADA CON SISTEMAS AUTÓNOMOS
// =================================================================

class MenuSystem {
    constructor() {
        this.isOpen = false;
        this.currentTab = 'main';
        this.settings = {
            dayMode: false,
            speedMultiplier: 1.0,
            blurLevel: '15px'
        };
        this.playerData = {};
        this.players = [];
        
        // NUEVO: Datos de sistemas autónomos
        this.economicData = {
            mercados: {},
            estadoGeneral: 'neutral',
            ultimaActualizacion: null
        };
        this.activeEvents = [];
        this.playerStats = {};
        this.economicUpdateInterval = null;
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupDragSystem();
        this.setupEconomicDisplay(); // NUEVO
        this.notifyLuaReady();
        
        console.log('🚀 Sistema de Menú inicializado con módulos autónomos');
    }

    setupEventListeners() {
        // Teclado
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                this.close();
            }
        });

        // Mensajes NUI
        window.addEventListener('message', (e) => this.handleNuiMessage(e.data));
    }

    setupDragSystem() {
        const header = document.querySelector('.menu-header[data-draggable="true"]');
        if (!header) return;

        let isDragging = false;
        let offset = { x: 0, y: 0 };
        const menu = document.getElementById('menu-principal');

        header.addEventListener('mousedown', (e) => {
            isDragging = true;
            const rect = menu.getBoundingClientRect();
            offset.x = e.clientX - rect.left;
            offset.y = e.clientY - rect.top;
            menu.style.cursor = 'grabbing';
            menu.style.transition = 'none';
        });

        document.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            
            const x = e.clientX - offset.x;
            const y = e.clientY - offset.y;

            // Limitar a los bordes de la pantalla
            const maxX = window.innerWidth - menu.offsetWidth;
            const maxY = window.innerHeight - menu.offsetHeight;

            const boundedX = Math.max(0, Math.min(x, maxX));
            const boundedY = Math.max(0, Math.min(y, maxY));

            menu.style.left = boundedX + 'px';
            menu.style.top = boundedY + 'px';
            menu.style.transform = 'none';
        });

        document.addEventListener('mouseup', () => {
            isDragging = false;
            menu.style.cursor = '';
            menu.style.transition = '';
            this.savePosition();
        });
    }

    // NUEVO: Sistema de visualización económica
    setupEconomicDisplay() {
        const economicBadge = document.createElement('div');
        economicBadge.className = 'economic-badge';
        economicBadge.innerHTML = `
            <div class="market-status" id="market-status">
                <span class="market-icon">📊</span>
                <span class="market-text">Cargando economía...</span>
            </div>
        `;
        
        const header = document.querySelector('.menu-header');
        if (header) {
            const titleContent = header.querySelector('.title-content');
            if (titleContent) {
                titleContent.appendChild(economicBadge);
            }
        }

        // Actualizar datos económicos periódicamente
        this.startEconomicUpdates();
    }

    startEconomicUpdates() {
        // Solicitar datos económicos cada 30 segundos
        this.economicUpdateInterval = setInterval(() => {
            if (this.isOpen) {
                this.callAction('get_economic_data');
            }
        }, 30000);
    }

    updateEconomicDisplay() {
        const statusElement = document.getElementById('market-status');
        if (!statusElement) return;

        const icon = statusElement.querySelector('.market-icon');
        const text = statusElement.querySelector('.market-text');
        
        if (!icon || !text) return;

        // Actualizar según el estado general
        switch(this.economicData.estadoGeneral) {
            case 'positivo':
                icon.textContent = '📈';
                text.textContent = 'Mercados Alcistas';
                statusElement.className = 'market-status positive';
                break;
            case 'negativo':
                icon.textContent = '📉';
                text.textContent = 'Mercados Bajistas';
                statusElement.className = 'market-status negative';
                break;
            case 'neutral':
                icon.textContent = '📊';
                text.textContent = 'Mercados Estables';
                statusElement.className = 'market-status neutral';
                break;
            default:
                icon.textContent = '📊';
                text.textContent = 'Sistema Económico';
                statusElement.className = 'market-status';
        }

        // Mostrar tooltip con detalles
        statusElement.title = this.generateEconomicTooltip();
    }

    generateEconomicTooltip() {
        let tooltip = 'Estado de Mercados:\\n';
        let marketCount = 0;
        
        for (const marketName in this.economicData.mercados) {
            const market = this.economicData.mercados[marketName];
            tooltip += `\\n${market.nombre}: $${market.precioActual.toLocaleString()} (${market.tendencia})`;
            marketCount++;
            
            if (marketCount >= 3) {
                tooltip += '\\n...';
                break;
            }
        }
        
        if (this.economicData.ultimaActualizacion) {
            const lastUpdate = new Date(this.economicData.ultimaActualizacion);
            tooltip += `\\n\\nÚltima actualización: ${lastUpdate.toLocaleTimeString()}`;
        }
        
        return tooltip;
    }

    savePosition() {
        const menu = document.getElementById('menu-principal');
        if (menu) {
            const position = {
                left: menu.style.left,
                top: menu.style.top
            };
            localStorage.setItem('menuPosition', JSON.stringify(position));
        }
    }

    loadPosition() {
        try {
            const saved = localStorage.getItem('menuPosition');
            if (saved) {
                const position = JSON.parse(saved);
                const menu = document.getElementById('menu-principal');
                if (menu) {
                    menu.style.left = position.left;
                    menu.style.top = position.top;
                    menu.style.transform = 'none';
                }
            }
        } catch (e) {
            console.warn('Error cargando posición:', e);
        }
    }

    showTab(tabName) {
        // Ocultar todas las pestañas
        document.querySelectorAll('.tab-content').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
        });

        // Mostrar pestaña seleccionada
        const targetTab = document.getElementById(`tab-${tabName}`);
        const targetBtn = document.querySelector(`[data-tab="${tabName}"]`);
        
        if (targetTab) targetTab.classList.add('active');
        if (targetBtn) targetBtn.classList.add('active');
        
        this.currentTab = tabName;

        // Acciones específicas por pestaña
        switch(tabName) {
            case 'players':
                this.refreshPlayerList();
                break;
            case 'economy': // NUEVO: Pestaña economía
                this.refreshEconomicData();
                break;
            case 'stats': // NUEVO: Pestaña estadísticas
                this.refreshPlayerStats();
                break;
        }
    }

    open() {
        if (this.isOpen) return;
        
        const menu = document.getElementById('menu-principal');
        if (!menu) return;

        menu.classList.add('active');
        this.isOpen = true;
        
        this.loadPosition();
        this.loadSettings();
        
        // Solicitar datos iniciales
        this.callAction('get_player_info');
        this.callAction('get_economic_data'); // NUEVO
        this.callAction('get_player_stats'); // NUEVO
    }

    close() {
        if (!this.isOpen) return;
        
        const menu = document.getElementById('menu-principal');
        if (menu) {
            menu.classList.remove('active');
        }
        
        this.isOpen = false;
        this.callAction('closeMenu');
    }

    minimize() {
        // Implementación futura
        this.showNotification('Menú minimizado', 'info');
    }

    // =================================================================
    // COMUNICACIÓN CON LUA
    // =================================================================

    callAction(action, payload = {}) {
        fetch(`https://${this.getResourceName()}/callAction`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: action,
                payload: payload
            })
        }).catch(error => {
            console.error('Error llamando acción Lua:', error);
            this.showNotification('Error de comunicación', 'error');
        });
    }

    notifyLuaReady() {
        this.callAction('uiReady');
    }

    getResourceName() {
        return typeof GetParentResourceName === 'function' ? 
               GetParentResourceName() : 'mi_menú_desenfoque';
    }

    // =================================================================
    // MANEJO DE MENSAJES NUI (ACTUALIZADO)
    // =================================================================

    handleNuiMessage(data) {
        if (!data || !data.action) return;

        try {
            switch (data.action) {
                case 'openMenu':
                    this.open();
                    break;

                case 'closeMenu':
                    this.close();
                    break;

                case 'showNotification':
                    this.showNotification(data.message, data.type);
                    break;

                case 'renderPlayerList':
                    this.renderPlayers(data.data);
                    break;

                case 'updatePlayerInfo':
                    this.updatePlayerInfo(data.playerData);
                    break;

                case 'initialState':
                    this.updateInitialState(data);
                    break;

                case 'updateMoney':
                    this.updateMoney(data.money);
                    break;

                case 'updateJob':
                    this.updateJob(data.job, data.grade);
                    break;

                // NUEVO: Manejo de datos de sistemas autónomos
                case 'updateEconomicData':
                    this.updateEconomicData(data.data);
                    break;

                case 'updatePlayerStats':
                    this.updatePlayerStats(data.stats);
                    break;

                case 'notificarEvento':
                    this.showEventNotification(data.evento);
                    break;
            }
        } catch (error) {
            console.error('Error procesando mensaje NUI:', error);
        }
    }

    // =================================================================
    // NUEVO: SISTEMA ECONÓMICO EN INTERFAZ
    // =================================================================

    updateEconomicData(economicData) {
        this.economicData = economicData;
        this.updateEconomicDisplay();
        
        // Actualizar pestaña de economía si está activa
        if (this.currentTab === 'economy') {
            this.renderEconomicData();
        }
    }

    renderEconomicData() {
        const economyTab = document.getElementById('tab-economy');
        if (!economyTab) return;

        let html = `
            <div class="tab-header">
                <h2>💰 Mercados Económicos</h2>
                <div class="header-actions">
                    <button class="btn-refresh" onclick="menuSystem.refreshEconomicData()" title="Actualizar mercados">
                        <span class="icon">🔄</span>
                    </button>
                </div>
            </div>
            
            <div class="economic-overview">
                <div class="overview-card ${this.economicData.estadoGeneral}">
                    <div class="overview-icon">${this.getEconomicIcon()}</div>
                    <div class="overview-content">
                        <h3>Estado General</h3>
                        <p class="overview-status">${this.getEconomicStatusText()}</p>
                        <small>Última actualización: ${new Date().toLocaleTimeString()}</small>
                    </div>
                </div>
            </div>

            <div class="markets-grid">
        `;

        for (const marketName in this.economicData.mercados) {
            const market = this.economicData.mercados[marketName];
            html += this.renderMarketCard(market);
        }

        html += `
            </div>
            
            <div class="economic-events">
                <h3 class="section-title">📊 Eventos Económicos Activos</h3>
                <div class="events-list">
                    ${this.renderActiveEvents()}
                </div>
            </div>
        `;

        economyTab.innerHTML = html;
    }

    renderMarketCard(market) {
        const trendIcon = market.tendencia === 'alcista' ? '📈' : 
                         market.tendencia === 'bajista' ? '📉' : '➡️';
        
        const trendClass = market.tendencia === 'alcista' ? 'positive' : 
                          market.tendencia === 'bajista' ? 'negative' : 'neutral';

        return `
            <div class="market-card ${trendClass}">
                <div class="market-header">
                    <span class="market-name">${this.capitalizeFirst(market.nombre)}</span>
                    <span class="market-trend ${trendClass}">${trendIcon} ${market.tendencia}</span>
                </div>
                <div class="market-price">$${market.precioActual.toLocaleString()}</div>
                <div class="market-details">
                    <small>Base: $${market.precioBase.toLocaleString()}</small>
                    <small>Volatilidad: ${(market.volatilidad * 100).toFixed(1)}%</small>
                </div>
            </div>
        `;
    }

    renderActiveEvents() {
        if (this.activeEvents.length === 0) {
            return '<div class="empty-state"><div class="empty-icon">⚡</div><p>No hay eventos activos</p></div>';
        }

        return this.activeEvents.map(event => `
            <div class="event-item">
                <span class="event-icon">🎯</span>
                <div class="event-content">
                    <strong>${this.formatEventName(event.tipo)}</strong>
                    <small>${event.timestamp}</small>
                </div>
            </div>
        `).join('');
    }

    getEconomicIcon() {
        switch(this.economicData.estadoGeneral) {
            case 'positivo': return '📈';
            case 'negativo': return '📉';
            default: return '📊';
        }
    }

    getEconomicStatusText() {
        switch(this.economicData.estadoGeneral) {
            case 'positivo': return 'Mercados en crecimiento';
            case 'negativo': return 'Mercados en corrección';
            default: return 'Mercados estables';
        }
    }

    refreshEconomicData() {
        this.callAction('get_economic_data');
        this.showNotification('Actualizando datos económicos...', 'info');
    }

    // =================================================================
    // NUEVO: SISTEMA DE ESTADÍSTICAS EN INTERFAZ
    // =================================================================

    updatePlayerStats(stats) {
        this.playerStats = stats;
        
        if (this.currentTab === 'stats') {
            this.renderPlayerStats();
        }
    }

    renderPlayerStats() {
        const statsTab = document.getElementById('tab-stats');
        if (!statsTab) return;

        const stats = this.playerStats;
        
        statsTab.innerHTML = `
            <div class="tab-header">
                <h2>📊 Estadísticas de Uso</h2>
            </div>

            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon">🚪</div>
                    <div class="stat-content">
                        <h3>${stats.menuOpens || 0}</h3>
                        <p>Aperturas de Menú</p>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon">⚡</div>
                    <div class="stat-content">
                        <h3>${stats.actionsPerformed || 0}</h3>
                        <p>Acciones Realizadas</p>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon">🔀</div>
                    <div class="stat-content">
                        <h3>${stats.playersTeleported || 0}</h3>
                        <p>Teletransportes</p>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon">💬</div>
                    <div class="stat-content">
                        <h3>${stats.chatMessagesSent || 0}</h3>
                        <p>Mensajes Chat</p>
                    </div>
                </div>
            </div>

            ${stats.lastAction ? `
                <div class="recent-activity">
                    <h3 class="section-title">Última Actividad</h3>
                    <div class="activity-item">
                        <span class="activity-type">${this.formatActionName(stats.lastAction.tipo)}</span>
                        <span class="activity-time">${stats.lastAction.timestamp}</span>
                    </div>
                </div>
            ` : ''}

            ${stats.firstUse ? `
                <div class="usage-info">
                    <small>Primer uso: ${stats.firstUse}</small>
                </div>
            ` : ''}
        `;
    }

    refreshPlayerStats() {
        this.callAction('get_player_stats');
    }

    // =================================================================
    // SISTEMA DE JUGADORES (ORIGINAL)
    // =================================================================

    refreshPlayerList() {
        this.callAction('request_player_data');
        
        const list = document.getElementById('players-list');
        if (list) {
            list.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">⏳</div>
                    <p>Cargando jugadores...</p>
                </div>
            `;
        }
    }

    renderPlayers(data) {
        const list = document.getElementById('players-list');
        if (!list) return;
        
        const players = data?.players || [];
        const total = data?.total || 0;

        if (players.length === 0) {
            list.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">👥</div>
                    <p>No hay jugadores cercanos</p>
                    <button class="btn-secondary" onclick="menuSystem.refreshPlayerList()">
                        Actualizar Lista
                    </button>
                </div>
            `;
            return;
        }

        list.innerHTML = players.map(player => `
            <div class="player-item" onclick="menuSystem.teleportToPlayer(${player.id})">
                <div class="player-name">${this.escapeHtml(player.name)}</div>
                <div class="player-details">
                    ${player.distance ? `<span>${player.distance}m</span>` : ''}
                    ${player.ping ? `<span>${player.ping}ms</span>` : ''}
                </div>
            </div>
        `).join('');
    }

    teleportToPlayer(playerId) {
        this.callAction('teleport_to_player', { targetId: playerId });
        this.showNotification('Iniciando teletransporte...', 'info');
    }

    // =================================================================
    // SISTEMA DE CONFIGURACIÓN (ORIGINAL)
    // =================================================================

    updateInitialState(data) {
        if (data.playerData) {
            this.updatePlayerInfo(data.playerData);
        }
        
        if (data.settings) {
            if (data.settings.dayMode !== undefined) {
                this.settings.dayMode = data.settings.dayMode;
                this.updateDayModeDisplay();
            }
            
            if (data.settings.speedMultiplier !== undefined) {
                this.settings.speedMultiplier = data.settings.speedMultiplier;
                this.updateSpeedDisplay();
            }
        }

        // NUEVO: Cargar datos de sistemas autónomos
        if (data.economicData) {
            this.updateEconomicData(data.economicData);
        }
        
        if (data.activeEvents) {
            this.activeEvents = data.activeEvents;
        }
        
        if (data.playerStats) {
            this.updatePlayerStats(data.playerStats);
        }
    }

    updatePlayerInfo(playerData) {
        this.playerData = playerData;
        
        // Actualizar UI
        const nameElement = document.getElementById('player-name');
        const jobElement = document.getElementById('player-job');
        
        if (nameElement) {
            nameElement.textContent = playerData.name || 'Jugador';
        }
        
        if (jobElement) {
            jobElement.textContent = playerData.job || 'Desempleado';
        }
    }

    updateMoney(amount) {
        console.log('Dinero actualizado:', amount);
    }

    updateJob(job, grade) {
        const jobElement = document.getElementById('player-job');
        if (jobElement) {
            jobElement.textContent = job || 'Desempleado';
        }
    }

    updateDayModeDisplay() {
        const icon = document.getElementById('day-mode-icon');
        const text = document.getElementById('day-mode-text');
        
        if (icon && text) {
            if (this.settings.dayMode) {
                icon.textContent = '☀️';
                text.textContent = 'Modo Día: ON';
            } else {
                icon.textContent = '🌙';
                text.textContent = 'Modo Día: OFF';
            }
        }
    }

    toggleDayMode() {
        this.settings.dayMode = !this.settings.dayMode;
        this.callAction('toggle_siempre_dia', { estado: this.settings.dayMode });
        this.updateDayModeDisplay();
    }

    updateSpeedDisplay() {
        const slider = document.getElementById('speed-slider');
        const value = document.getElementById('speed-value');
        
        if (slider && value) {
            slider.value = this.settings.speedMultiplier;
            value.textContent = this.settings.speedMultiplier.toFixed(1) + 'x';
        }
    }

    updateSpeedValue(value) {
        const valueElement = document.getElementById('speed-value');
        if (valueElement) {
            valueElement.textContent = parseFloat(value).toFixed(1) + 'x';
        }
    }

    applySpeedMultiplier() {
        const slider = document.getElementById('speed-slider');
        if (!slider) return;
        
        const speed = parseFloat(slider.value);
        this.settings.speedMultiplier = speed;
        this.callAction('ajustar_velocidad', { velocidad: speed });
        this.showNotification(`Velocidad ajustada a ${speed.toFixed(1)}x`, 'success');
    }

    setBlurLevel(level) {
        this.callAction('set_blur_level', { level: level });
        this.showNotification(`Blur ajustado a ${level}`, 'info');
        
        const currentBlur = document.getElementById('current-blur');
        if (currentBlur) {
            currentBlur.textContent = level;
        }
    }

    sendChatMessage() {
        const input = document.getElementById('chat-message');
        if (!input) return;
        
        const message = input.value.trim();
        
        if (!message) {
            this.showNotification('Escribe un mensaje primero', 'error');
            return;
        }

        this.callAction('enviar_mensaje_chat', { mensaje: message });
        input.value = '';
        this.showNotification('Mensaje enviado al chat', 'success');
    }

    executeAction(action) {
        this.callAction(action);
    }

    // =================================================================
    // NUEVO: SISTEMA DE NOTIFICACIONES DE EVENTOS
    // =================================================================

    showEventNotification(evento) {
        const message = this.formatEventNotification(evento);
        this.showNotification(message, 'info', 7000);
    }

    formatEventNotification(evento) {
        switch(evento.tipo) {
            case 'boom_immobiliario':
                return '🏠 BOOM INMOBILIARIO: Precios de propiedades +20%!';
            case 'crisis_combustible':
                return '⛽ CRISIS COMBUSTIBLE: Precios de vehículos +15%!';
            case 'tecnologia_avance':
                return '💻 AVANCE TECNOLÓGICO: Recursos más accesibles!';
            case 'mercado_estable':
                return '📊 MERCADO ESTABLE: Precios normalizados!';
            default:
                return `⚡ Evento: ${evento.tipo}`;
        }
    }

    // =================================================================
    // SISTEMA DE NOTIFICACIONES (ORIGINAL)
    // =================================================================

    showNotification(message, type = 'info', duration = 5000) {
        const container = document.getElementById('notification-system');
        if (!container) return;

        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        container.appendChild(notification);

        // Animación de entrada
        setTimeout(() => notification.classList.add('show'), 10);

        // Auto-remover
        if (duration > 0) {
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => {
                    if (notification.parentNode) {
                        notification.remove();
                    }
                }, 300);
            }, duration);
        }

        return notification;
    }

    // =================================================================
    // UTILIDADES (ACTUALIZADAS)
    // =================================================================

    escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    capitalizeFirst(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }

    formatEventName(eventType) {
        const names = {
            'boom_immobiliario': 'Boom Inmobiliario',
            'crisis_combustible': 'Crisis de Combustible', 
            'tecnologia_avance': 'Avance Tecnológico',
            'mercado_estable': 'Mercado Estable'
        };
        return names[eventType] || eventType;
    }

    formatActionName(actionType) {
        const names = {
            'ejecutar_accion_uno': 'Acción Rápida',
            'toggle_siempre_dia': 'Modo Día/Noche',
            'enviar_mensaje_chat': 'Mensaje Chat',
            'ajustar_velocidad': 'Ajuste Velocidad',
            'teleport_to_player': 'Teletransporte'
        };
        return names[actionType] || actionType;
    }

    loadSettings() {
        try {
            const saved = localStorage.getItem('menuSettings');
            if (saved) {
                this.settings = { ...this.settings, ...JSON.parse(saved) };
                this.updateDayModeDisplay();
                this.updateSpeedDisplay();
            }
        } catch (e) {
            console.warn('Error cargando configuraciones:', e);
        }
    }

    saveSettings() {
        localStorage.setItem('menuSettings', JSON.stringify(this.settings));
    }
}

// =================================================================
// INICIALIZACIÓN Y FUNCIONES GLOBALES (ACTUALIZADAS)
// =================================================================

let menuSystem;

document.addEventListener('DOMContentLoaded', () => {
    menuSystem = new MenuSystem();
});

// Funciones globales para onclick
function showTab(tab) {
    if (menuSystem) menuSystem.showTab(tab);
}

function toggleDayMode() {
    if (menuSystem) menuSystem.toggleDayMode();
}

function refreshPlayerList() {
    if (menuSystem) menuSystem.refreshPlayerList();
}

function updateSpeedDisplay(value) {
    if (menuSystem) menuSystem.updateSpeedValue(value);
}

function applySpeedMultiplier() {
    if (menuSystem) menuSystem.applySpeedMultiplier();
}

function setBlurLevel(level) {
    if (menuSystem) menuSystem.setBlurLevel(level);
}

function sendChatMessage() {
    if (menuSystem) menuSystem.sendChatMessage();
}

function executeAction(action) {
    if (menuSystem) menuSystem.executeAction(action);
}

// NUEVAS: Funciones para sistemas autónomos
function refreshEconomicData() {
    if (menuSystem) menuSystem.refreshEconomicData();
}

function refreshPlayerStats() {
    if (menuSystem) menuSystem.refreshPlayerStats();
}

function closeMenu() {
    if (menuSystem) menuSystem.close();
}

function minimizeMenu() {
    if (menuSystem) menuSystem.minimize();
}

// Polyfill para GetParentResourceName
if (typeof GetParentResourceName === 'undefined') {
    window.GetParentResourceName = () => 'mi_menú_desenfoque';
}

console.log('✅ Interfaz de usuario cargada con sistemas autónomos');