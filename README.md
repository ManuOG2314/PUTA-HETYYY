# PUTA-HETYYY — Roguelike de Ciencia Ficción en Godot 4

Un roguelike de disparos en vista superior (top-down) inspirado en *The Binding of Isaac*, desarrollado en Godot 4.7. El juego cuenta con generación procedimental de niveles, combate elemental, sistemas de mejoras pasivas y un HUD responsivo y dinámico.

---

## 🚀 Características Principales

### 🗺️ Generación Procedimental de Niveles
- Niveles formados por múltiples salas generadas algorítmicamente en una cuadrícula.
- Tipos de sala: `START` (Inicio), `NORMAL` (Combate), `TREASURE` (Tesoro con mejoras de pedestal) y `BOSS` (Jefe de nivel).
- Las puertas se sellan dinámicamente al entrar a una sala de combate no despejada y se reabren solo cuando todos los enemigos han sido derrotados.

### 🔫 Combate Avanzado del Jugador
- **Estadísticas Dinámicas**: Vida Máxima, Vida Actual, Daño, Velocidad y Cadencia de disparo.
- **Modificadores de Disparo**:
  - **Lágrimas Perforadoras**: Proyectiles que traspasan múltiples enemigos.
  - **Lágrimas Divisoras (Split)**: Las lágrimas se dividen en proyectiles adicionales en direcciones perpendiculares al impactar.
  - **Explosión al Eliminar (Explode on Kill)**: Detonaciones en cadena en el área al vencer a un enemigo.
  - **Efectos de Estado Elementales**: Modifican el tipo de daño y aplican estados alterados.

### 🧪 Sistema de Reacciones y Daño Elemental
- **Fuego (Burn)**: Inflige daño continuo rápido (1 de daño cada 0.5 segundos durante 2 segundos). Colorea los números de daño en naranja.
- **Hielo (Freeze/Slow)**: Ralentiza el movimiento del enemigo al 50% durante 2.5 segundos. Colorea los números de daño en cian.
- **Veneno (Poison)**: Corrosión ácida de larga duración (1 de daño cada 1.0 segundos durante 5 segundos). Colorea los números de daño en verde.
- **Números de Daño Flotantes**: Textos emergentes animados con efecto pop-up y desvanecimiento gradual, coloreados según el elemento aplicado.

### 🤖 Inteligencia Artificial de Enemigos
- **Enemigo Cuerpo a Cuerpo (Melee)**: Persigue agresivamente al jugador e inflige daño por contacto. Aplica empuje (knockback) y un flash visual blanco al recibir impactos.
- **Enemigo a Distancia (Ranged)**: Dron de ataque que mantiene una distancia segura del jugador (retrocede si se le acerca demasiado) y dispara proyectiles esquivables periódicamente.
- **Spawn Seguro**: Los enemigos solo aparecen en posiciones del suelo libres de obstáculos sólidos, evitando quedar atrapados en muros.

### 📺 HUD y Experiencia de Juego (Juice)
- **HUD Glassmorphic**: Interfaz elegante en la parte inferior con efecto de vidrio esmerilado, barra doble de vida (salud instantánea en rojo y barra de impacto demorada en amarillo) y cuadrícula de estadísticas.
- **Feedback Visual**: Parpadeo de invulnerabilidad tras ser golpeado, sacudidas de pantalla (Screen Shake) proporcionales al daño recibido e indicaciones animadas de pulso en el HUD al obtener buffs.
- **Condiciones de Fin**: Pantallas de Game Over y Victoria integradas al derrotar al jefe o al perder toda la vida.

---

## 📂 Mapa del Proyecto

Los scripts principales y sus responsabilidades:

- 🎮 **[main.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/core/main.gd)**: Controla el flujo principal del juego, las transiciones suaves de cámara y pantalla entre salas, el efecto de sacudida y las condiciones de fin de partida.
- 👨‍🚀 **[player.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/entities/player/player.gd)**: Controla el movimiento, animación, invulnerabilidad y el disparo del jugador junto a sus buffs elementales y de proyectiles.
- 👾 **[enemy.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/entities/enemies/enemy.gd)**: Clase base para la IA enemiga. Gestiona vida, empuje (knockback), flash por daño, efectos de estado DoT (daño en el tiempo) y detonaciones al morir.
- 🛸 **[enemy_ranged.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/entities/enemies/enemy_ranged.gd)**: Subclase de enemigo a distancia con comportamiento de control de rango y disparo de proyectiles al jugador.
- 🧪 **[enemy_tear.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/combat/enemy_tear.gd)**: Comportamiento de los proyectiles enemigos que dañan al jugador.
- 📦 **[item_pedestal.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/items/item_pedestal.gd)**: Administra los pedestales de las salas de tesoro, otorgando buffs estadísticos o chips elementales/modificadores.
- 🚪 **[room.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/world/room.gd)**: Construye y carga el layout físico y lógico de las salas, bloquea/desbloquea puertas físicas mediante el TileMap y genera enemigos de forma inteligente.
- 🔢 **[game_constants.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/core/game_constants.gd)**: Contiene los enums para direcciones, tipos de daño elemental, tipos de sala y constantes geométricas globales.
- 📊 **[hud.gd](file:///mnt/vol_sda1/hey/PUTA-HETYYY/src/ui/hud.gd)**: Actualiza y anima la interfaz de usuario.

---

## 🗺️ Hoja de Ruta (Roadmap) y Próximos Pasos

1. **Temáticas de Planetas e Interacciones de Sala**:
   - Crear distintos planetas con peligros ambientales únicos (ej. Mundo Ácido que consume oxígeno o vida a menos que se use un amuleto adecuado).
   - Añadir salas de tienda (`SHOP`) para gastar cristales/monedas acumulados en el nivel.
2. **Sistema de Amuletos y Sinergias (Estilo Balatro)**:
   - Crear una pestaña de inventario de amuletos equipables que ofrezcan multiplicadores de daño, mejoras condicionales (ej. +50% de daño si estás a 1 HP) o inmunidades ambientales.
3. **Árbol de Talentos y Selección de Personajes**:
   - Menú inicial para elegir diferentes astronautas con habilidades pasivas únicas.
   - Guardar cristales de jefes para desbloquear ventajas permanentes entre partidas.
4. **Combates de Jefes Avanzados**:
   - Diseñar patrones de ataque complejos en fases en la sala de tipo `BOSS`.
