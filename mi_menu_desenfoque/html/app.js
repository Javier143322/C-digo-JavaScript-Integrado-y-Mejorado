// Definimos la función para comunicación con FiveM al principio
const GetParentResourceName = () => {
    return 'mi_menú_desenfoque'; 
};

// =================================================================
// FUNCIÓN AUTO-EJECUTABLE PARA MANTENER EL ÁMBITO LIMPIO
// =================================================================
(() => {
    class GameViewManager {
        constructor(numViews = 2, blurStrength = '20px') {
            this.NUM_VIEWS = numViews;
            this.BLUR_STRENGTH = blurStrength;
            this.resizeTimeout = null;
            this.VIEWS_ARRAY = [];
            this.CONTAINER = null;
            this.DEBOUNCE_TIME = 66; 
            
            window.gameViewManager = this; 
            this.init();
        }
        
        _createContainer() {
            if (this.CONTAINER) {
                this.CONTAINER.remove();
            }

            const container = document.createElement('div');
            container.id = 'gameview-background-container';
            container.style.cssText = `
                position: fixed; 
                top: 50%; 
                left: 50%; 
                transform: translate(-50%, -50%);
                display: flex; 
                gap: 2vw; 
                z-index: -100;
                width: 80vw; 
                height: 80vh; 
                pointer-events: none;
                visibility: hidden; 
            `;
            this.CONTAINER = container;
            document.body.appendChild(container);
        }
        
        _createViews() {
            this.VIEWS_ARRAY.forEach(view => view.remove());
            this.VIEWS_ARRAY = [];

            for (let i = 0; i < this.NUM_VIEWS; i++) {
                const screen = document.createElement('object');
                screen.type = 'application/x-cfx-game-view'; 
                screen.id = `game-view-${i + 1}`;
                screen.style.cssText = `
                    flex: 1; 
                    width: 100%; 
                    height: 100%; 
                    filter: blur(${this.BLUR_STRENGTH});
                    transition: filter 0.3s ease;
                `;
                this.VIEWS_ARRAY.push(screen);
                this.CONTAINER.appendChild(screen);
            }
        }
        
        _setupResizeListener() {
            const resizeHandler = () => {
                if (this.resizeTimeout) {
                    clearTimeout(this.resizeTimeout);
                }
                this.resizeTimeout = setTimeout(() => {
                    // Lógica optimizada 
                }, this.DEBOUNCE_TIME);
            };
            window.addEventListener('resize', resizeHandler);
        }
        
        init() {
            this._createContainer();
            this._createViews();
            this._setupResizeListener();
        }
        
        // =================================================================
        // FUNCIONES DE CONTROL (show/hide/setBlur/setNumViews)
        // =================================================================
        show() {
            if (this.CONTAINER) {
                this.CONTAINER.style.visibility = 'visible';
                this.VIEWS_ARRAY.forEach(view => {
                    view.style.filter = `blur(${this.BLUR_STRENGTH})`;
                });
            }
        }

        hide() {
            if (this.CONTAINER) {
                this.VIEWS_ARRAY.forEach(view => {
                    view.style.filter = 'none';
                });
                setTimeout(() => {
                    this.CONTAINER.style.visibility = 'hidden';
                }, 300); 
            }
        }
        
        setBlurLevel(newLevel) {
            this.VIEWS_ARRAY.forEach(view => {
                view.style.filter = `blur(${newLevel})`;
            });
            this.BLUR_STRENGTH = newLevel;
        }

        setNumViews(newCount) {
            if (newCount === this.NUM_VIEWS) return;

            this.NUM_VIEWS = newCount;
            this.VIEWS_ARRAY = [];
            this._createContainer();
            this._createViews();
            
            if (window.gameViewManager.CONTAINER && window.gameViewManager.CONTAINER.style.visibility === 'visible') {
                this.show();
            }
        }
    }
    
    new GameViewManager(2, '20px');

    
    // =================================================================
    // ESCUCHA DE EVENTOS DE FIVEM (NUI CALLBACKS)
    // =================================================================
    window.addEventListener('message', function (event) {
        const data = event.data;

        if (!window.gameViewManager) {
            console.error('GameViewManager no inicializado.');
            return; 
        }

        switch (data.action) {
            case 'openMenu':
                window.gameViewManager.show(); 
                break;

            case 'closeMenu':
                window.gameViewManager.hide(); 
                break;

            case 'setBlurLevel':
                if (data.level) {
                    window.gameViewManager.setBlurLevel(data.level);
                }
                break;
                
            case 'changeViewCount':
                if (data.count && typeof data.count === 'number') {
                    window.gameViewManager.setNumViews(data.count);
                }
                break;
                
            case 'renderPlayerList':
                if (data.data && window.renderPlayerList) {
                    window.renderPlayerList(data.data);
                }
                break;
        }
    });

    // =================================================================
    // DEBUGGING Y CONFIRMACIÓN A LUA
    // =================================================================
    console.log("GameViewManager y lógica de UI cargados correctamente.");

    fetch(`https://${GetParentResourceName()}/uiReady`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            status: 'ok'
        })
    }).then(resp => resp.json()).then(resp => console.log(resp));

})(); 
