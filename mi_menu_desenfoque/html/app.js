// =================================================================
// APP.JS - VERSIÓN FINAL MEJORADA
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
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupDragSystem();
        this.notifyLuaReady();
        
        console.log('🚀 Sistema de Menú inicializado');
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

        // Acciones específicas
        if (tabName === 'players') {
            this.refreshPlayerList();
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
    // MANEJO DE MENSAJES NUI
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
            }
        } catch (error) {
            console.error('Error procesando mensaje NUI:', error);
        }
    }

    // =================================================================
    // SISTEMA DE JUGADORES
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
    // SISTEMA DE CONFIGURACIÓN
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
        // Actualizar dinero en la UI si es necesario
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
    // SISTEMA DE NOTIFICACIONES
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
    // UTILIDADES
    // =================================================================

    escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
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
// INICIALIZACIÓN Y FUNCIONES GLOBALES
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

console.log('✅ Interfaz de usuario cargada correctamente');