// IIFE para encapsular el script y mantener el alcance limpio
(() => {
    // =================================================================
    // CONFIGURACIÓN: Ajuste estos valores
    // =================================================================
    const NUM_VIEWS = 2; // Número de vistas del juego a crear
    const BLUR_STRENGTH = '15px'; // La intensidad del desenfoque
    const Z_INDEX_BACKGROUND = '-100'; // Asegura que esté muy por detrás de cualquier UI

    // =================================================================
    // LÓGICA DE CREACIÓN DE VISTAS DEL JUEGO
    // =================================================================

    const container = document.createElement('div');
    container.id = 'gameview-container';
    
    // Configuración CSS mínima en JS (posicionamiento y layout)
    container.style.cssText = `
        position: fixed; 
        top: 50%; 
        left: 50%; 
        transform: translate(-50%, -50%);
        display: flex; 
        gap: 20px;
        z-index: ${Z_INDEX_BACKGROUND};
    `;
    
    // Almacenamiento de las referencias de los elementos para el redimensionamiento
    const gameViews = [];

    // Crear y configurar todas las vistas del juego
    for (let i = 0; i < NUM_VIEWS; i++) {
        const screen = document.createElement('object');
        screen.type = 'application/x-cfx-game-view';
        screen.id = `game-view-${i + 1}`;
        
        // Aplicamos el 'filter: blur()' directamente a la vista del juego
        screen.style.filter = `blur(${BLUR_STRENGTH})`;
        
        gameViews.push(screen);
        container.appendChild(screen);
    }
    
    document.body.appendChild(container);

    // =================================================================
    // LÓGICA DE REDIMENSIONAMIENTO OPTIMIZADA (Throttle/Debounce)
    // =================================================================

    // Función que calcula y aplica el nuevo tamaño
    const applyViewSize = () => {
        // Usamos una división más simple para mantener la relación de aspecto
        const newWidth = Math.floor(window.innerWidth / (NUM_VIEWS + 1)); 
        const newHeight = Math.floor(window.innerHeight / 2); 
        
        const widthStyle = `${newWidth}px`;
        const heightStyle = `${newHeight}px`;

        gameViews.forEach(view => {
            view.style.width = widthStyle;
            view.style.height = heightStyle;
        });
    };

    // Función Debounce para limitar la frecuencia de llamadas a 'applyViewSize'
    // Evita que la función se ejecute cientos de veces al arrastrar la ventana,
    // mejorando el rendimiento.
    let resizeTimeout;
    const debouncedResize = () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(applyViewSize, 66); // 66ms ~ 15 FPS
    };

    // Aplicar tamaño inicial
    applyViewSize();

    // Configurar el evento de redimensionamiento con la función optimizada
    window.addEventListener('resize', debouncedResize);

})();
