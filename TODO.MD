# 📋 TODO — Hoja de Ruta y Tareas del Proyecto

---

## ✅ Tareas Completadas

### 🗺️ Navegación y Economía (Fase 1)
* [x] **Minimapa Interactivo en Tiempo Real**:
  - Dibuja el mapa de salas con niebla de guerra (revela salas adyacentes).
  - Resalta la sala actual del jugador con borde pulsante.
  - Iconos y colores distintivos para salas especiales: Inicio (Azul), Tesoro (`✦` Oro), Tienda (`💎` Esmeralda), Jefe (`💀` Carmesí).
* [x] **Economía de Cristales de Energía**:
  - Los enemigos sueltan cristales magnéticos de plasma al morir que vuelan hacia el jugador.
  - Los jefes derrotados expulsan una fuente de cristales de alto valor.
  - Contador de cristales integrado al HUD en tiempo real.
* [x] **Implementación de la Sala de Tienda (`SHOP`)**:
  - Generación procedimental de salas de tienda en extremos del nivel.
  - Spawneo de 3 artículos con precios en cristales (Curación por 3💎, Mejora de Estadísticas por 6💎, Núcleo/Chip Avanzado por 10💎).
  - Feedback visual con advertencia animada si no se tienen suficientes cristales.

### ⚡ Sistema Elemental y Combate
* [x] **Números de Daño Flotantes**: Textos emergentes animados con colores dinámicos según el tipo de daño (Físico, Fuego, Hielo, Veneno, Electricidad).
* [x] **Enemigo a Distancia**: Dron de ataque con IA de mantenimiento de rango y proyectiles esquivables (`enemy_ranged.gd`).
* [x] **Núcleos y Modificadores de Poder**:
  - *Fuego (Burn)*: Daño continuo en el tiempo (1 de daño cada 0.5s durante 2s).
  - *Hielo (Freeze)*: Ralentización del 50% de velocidad durante 2.5s.
  - *Veneno (Poison)*: Corrosión de larga duración (1 de daño cada 1.0s durante 5s).
  - *Electricidad (Chain Shock)*: **Núcleo Voltaico** que encadena arcos de plasma eléctrico a enemigos cercanos con destello visual amarillo.
  - *Modificadores Pasivos*: Perforación (`Pierce`), Disparo Divisor (`Split`) y Detonación en Cadena (`Explode on Kill`).
* [x] **Animación y Visuales en Pedestales**: Orbes brillantes animados en levitación con los colores de cada mejora.

### 🖥️ HUD y Experiencia de Usuario (UI/UX)
* [x] **Panel de Estado de Combate**: El HUD muestra en tiempo real la Vida, Daño, Velocidad, Cadencia, Núcleo Elemental Activo y Chips Especiales equipados.
* [x] **Corrección de Bugs Críticos**: Arreglado spawn de enemigos dentro de muros y sincronización de señales en proyectiles.

---

## 📌 Próximas Tareas Pendientes (Roadmap)

### ✨ Fase 2: VFX y Jugosidad Visual (*Game Juice*)
- [ ] **Partículas GPU de Impacto (`GPUParticles2D`)**: Chispas y fragmentos de plasma al impactar enemigos o muros.
- [ ] **Estelas de Plasma para Proyectiles**: Trazas de luz que sigan a los disparos según su elemento.
- [ ] **Viñeta de Alerta Crítica**: Borde pulsante en pantalla cuando el jugador tenga 1 o 2 puntos de salud restante.

### 👾 Fase 3: Jefe con Fase 2 (*Enrage Mode*)
- [ ] **Sobrecarga del Jefe (<50% HP)**: Aura enrage roja/púrpura, mayor velocidad de ataque y disparo.
- [ ] **Invocación de Drones**: El jefe invoca 2 drones escolta al entrar en Fase 2.
- [ ] **Patrón de Ataque Avanzado**: Barrido de láser rotatorio orbital o lluvia de proyectiles densa.

### 🎵 Fase 4: Gestor de Sonido Procedural (*SFX Synth*)
- [ ] **AudioStreamGenerator Integrado**:
  - Efectos de disparo, impacto de bala, daño sufrido, recolección de cristales/ítems y explosiones sintetizados en tiempo real.