
(() => {
    class GameViewManager {
        constructor(numViews = 2, blurStrength = '20px') {
            this.NUM_VIEWS = numViews;
            this.BLUR_STRENGTH = blurStrength;
            this.resizeTimeout = null;
            this.VIEWS_ARRAY = [];
            this.CONTAINER = null;
            this.DEBOUNCE_TIME = 66; 
            this.init();
        }
        _createContainer() {
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
            `;
            this.CONTAINER = container;
            document.body.appendChild(container);
        }
        _createViews() {
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
    }
    const gameViewManagerInstance = new GameViewManager(2, '20px');
})();
    // Remueve o comenta este código de prueba:
    // setInterval(toggleBlur, 5000); 

})(); 
// <--- Aquí termina el código que ya tienes.
// =================================================================
// CÓDIGO AÑADIDO: ESCUCHA DE EVENTOS DE FIVEM (NUI CALLBACKS)
// =================================================================

window.addEventListener('message', function (event) {
    const data = event.data;

    // Aseguramos que el objeto 'gameViewManager' exista antes de usarlo
    if (!window.gameViewManager) {
        console.error('GameViewManager no inicializado.');
        return; 
    }

    switch (data.action) {
        case 'openMenu':
            // Muestra el efecto blur de la vista del juego
            window.gameViewManager.show(); 
            // Muestra el contenedor principal del menú (usando la clase CSS)
            document.querySelector('.menu-container').style.display = 'flex';
            break;

        case 'closeMenu':
            // Oculta el efecto blur de la vista del juego
            window.gameViewManager.hide(); 
            // Oculta el contenedor principal del menú
            document.querySelector('.menu-container').style.display = 'none';
            break;

        case 'setBlurLevel':
            // Permite cambiar la intensidad del blur desde el juego
            if (data.level) {
                window.gameViewManager.setBlur(data.level);
            }
            break;
            
        // Puedes añadir más acciones aquí si tu menú crece
    }
});
