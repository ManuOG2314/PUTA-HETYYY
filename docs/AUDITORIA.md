# 📋 Auditoría del Proyecto — hacia un juego "de verdad"

> Revisión completa del código y estructura del proyecto (Godot 4.7, roguelike tipo Isaac).
> Objetivo: convertir el prototipo actual en un proyecto serio, con demos jugables que evolucionen por etapas.

---

## 1. Veredicto general

**Lo bueno** (y hay que reconocerlo): la base está sorprendentemente bien encaminada para un prototipo.
Existe separación de carpetas (`src/core`, `src/world`, `src/entities`, `src/combat`, `src/ui`, `src/items`),
hay una clase de constantes (`game_constants.gd`), señales en vez de accesos directos en varios sitios,
generación procedural con tipos de sala, economías, estados elementales, minimapa, HUD… Es un loop de
juego real, no un sandbox de pruebas.

**El problema central**: es un prototipo que creó como pudo y ahora hay que *institucionalizarlo*.
Viven de patrones frágiles (números mágicos, `await` sueltos, copia/pega, rutas de nodos hardcodeadas)
que funcionan hoy, pero cada nueva feature va a costar el doble y romper cosas del doble de rápido.

---

## 2. Hallazgos — Estructura y repositorio

### 2.1 🔴 El repo está "a medias" tras la reorganización (URGENTE, riesgo de pérdida)
`git status` muestra **todos los scripts viejos en la raíz como DELETED** y los nuevos en `src/` como
UNTRACKED. Si alguien clona el repo ahora mismo en otro PC, **el juego no existe**: no hay código en
ningún commit. Son prácticamente 10 commits de trabajo sin guardar aunque localmente se vea todo.

**Acción**: hacer commit ya (`git add -A && git commit -m "refactor: mover todo a src/"`).
Hábito recomendado: commits pequeños + push, nunca dejar el repo "solo papeles".

### 2.2 🔴 Carpeta de assets caótica y Godot importándola
- `assets/` → assets limpios (bien ✅).
- `"assets que consegui porai/"` → **duplicado de los mismos PNGs con nombres con espacios**, incluidas
  versiones "No Outlines" que ni se usan. Godot está generando `.import` dentro de esa carpeta
  (¡está importando assets que no se usan!).
- `FS/` → archivos fuente de Aseprite (`.aseprite`), GIFs crudos, blobs como `ball.png` (51 KB) y
  `imtemto.aseprite` mezclados con recursos que sí usa el juego (`FS/ball.png` está cargado en
  `item_pedestal.gd`, `FS/wall.png`…).
- El *"Read Me.txt"* del asset pack demuestra que esa carpeta es un pack de Itch.io sin licencia
  verificada ni creditado en el README.

**Acciones**:
- Añadir archivo `.gdignore` (vacío) dentro de `"assets que consegui porai/"` y en cualquier carpeta
  de material crudo para que Godot NO la importe.
- Crear estructura definitiva:
  ```
  assets/            # solo lo que usa el juego (png, ttf)
    players/ tilesets/ ui/ weapons/ audio/ fonts/
  art_src/           # fuentes de .aseprite, gifs, exportaciones crudas (con .gdignore)
  docs/              # este documento, TODO, diagramas
  ```
- Créditos/licencia de assets de terceros en el README (los packs de Itch suelen exigirlo).
- Renombrar el proyecto: el nombre en `project.godot` (`"Isaacc ig"`) y del repo aparecerán siempre.
  No hay que quitarle la gracia, pero decidir "nombre de estudio/juego" define el tono del proyecto.

### 2.3 🟡 Configuración del proyecto mejorable (`project.godot`)
- `renderer/rendering_method="mobile"` + juego 2D pixel-art en PC: usar **`gl_compatibility`** (lo más
  estable y rápido para 2D) o forward_plus. "Mobile" es para móviles.
- `3d/physics_engine="Jolt Physics"` en un juego 2D: ruido de configuración que confunde; quitarlo.
- Las capas definidas son **solo de render** (`2d_render/layer_1..4`) pero las colisiones (mask 13,
  layer 2) usan números en crudo. Definir `layer_names/2d_physics/layer_1="Player"`, etc. y usar las
  constantes en el código/escenas.
- `window/stretch/aspect="expand"` con pixel-art suele dar tejas cortadas; evaluar `keep`.
- Falta `run/max_fps`, vsync y config de audio buses (no existe el bus `SFX`/`Music`).

### 2.4 🟡 Nada de autos: no hay Game manager, ni Audio, ni EventBus
- Game over = `get_tree().paused = true` + reload. No hay pausa (Esc), no hay menú principal, no hay
  transición de nivel 1→2 (se gana y fin).
- Recomendación de autoloads (esto es lo que separa "demo" de "proyecto"):
  | Autoload | Responsabilidad |
  |---|---|
  | `G` (o `GameState`) | run actual: piso, estadísticas acumuladas, semilla del piso, items |
  | `Events` (EventBus) | señales globales: `player_damaged`, `enemy_died`, `run_won`… elimina `get_tree().current_scene.has_method(...)` |
  | `Audio` | un solo punto para SFX/música (hoy: cero audio |

### 2.5 🟡 Sin audio ni export
- Cero sonido, cero `export_presets.cfg`. Para "ir haciendo demos", hace falta_workflow:
  `godot --headless --export-release "Windows Desktop" demo_vX.exe` + una Release en GitHub.
  Un binario descargable que la gente prueba es lo que convierte feedback en direcciones correctas.

### 2.6 🟢 CI mínima (cuando el repo esté sano)
GitHub Action con `godot --headless --import` + `--check-only` para los scripts detecta errores de
parseo antes de que hagan pull. Barato y evita el clásico "a mí te rompiste el juego".

---

## 3. Hallazgos — Arquitectura del código

### 3.1 🔴 Números mágicos por todas partes
Ejemplos reales:
- `room.gd`: tiles de muro codificados como `Vector2i(3, 0)`, puerta `Vector2i(33, 1)`.
- `main.gd`: offsets de llegada `half_w - 2.5`, `half_h - 2`.
- `item_pedestal.gd ↔ room.gd`: los tipos de buff se pasan como **ints comentados**:
  `p1.setup_pedestal(3, 3) # BuffType.HEALTH = 3` y `chip_type = randi_range(4, 10)`. Cambiar un enum
  rompe dos archivos distintos sin que el compilador avise.
- Precios de tienda, valores de enemigos, `0.4` de probabilidad de ranged… todos incrustados.

**Acción**: todo valor de balance y de tileset a `game_constants.gd` (o un `Balance.gd` estático), y
pasar enums reales (`Room.BuffType.HEALTH`) entre módulos, no ints con comentarios.

### 3.2 🔴 Sistema de items/Build no serializable
`item_pedestal.gd` define `BuffType`, nombres y colores en diccionarios sueltos; aplica el buff con
`_apply_buff(player)` llamando métodos a mano. Para un roguelike esto es el corazón y está acoplado a
UI+gameplay en un solo script.

**Acción (la mejora más rentable del proyecto)**: crear `ItemDef` como **Resource**:
```gdscript
# src/items/item_def.gd
class_name ItemDef extends Resource
@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var color: Color
@export var price: int
@export var rarity: int
func apply(player: Player) -> void: pass
```
y sub-recursos por item (`item_fire_core.tres`, etc.). Ventajas: cero código para añadir items, la
lista de items de un piso se arma con un folder de `.tres`, los pedestales/tienda/pools se generan
filtrando recursos, y el save del run es una lista de `ItemDef`.

### 3.3 🔴 Copia/pega masivo (las 3 clases enemigas repiten casi igual)
`enemy.gd`, `enemy_ranged.gd` y `boss.gd` **repiten el mismo bloque** de modulate por estado + knockback
+ `_animate_sprite` + reset de `_slow_timer`. Y `boss.gd` en su `_physics_process` copió el template del
Enemy pero rompe la lógica (nunca persigue; siempre velocidad 0 salvo knockback).

**Acción**: la máquina de estados no necesita ser sofisticada; basta con:
- Mover modulate/estados al `enemy.gd` en un solo `update_state_visuals()`.
- `enemy_ranged.gd` y `boss.gd` no deberían sobreescribir `_physics_process` completo; exponer
  `_chase(delta)` / `_strafe()` / `_attack()` que la base llama.
- `_animate_sprite` × 3 → un `AnimatedSprite2D` con `SpriteFrames` (Godot ya lo trae) o un helper
  compartido. Ahora mismo las animaciones están hardcodeadas con índices de frame mágicos
  (`[24,25,26,27]` "Row 3") — eso es exactamente lo que hace `SpriteFrames` para ti.

### 3.4 🔴 `await get_tree().create_timer(...)` como sistema de lógica
Está en cadencia de disparo, invulnerabilidad, DoT loops, ataques del boss, disparo del ranged, warning
de tienda… Problemas concretos:
1. `create_timer(1.0)` por defecto **sigue corriendo con `paused = true`** → tras Game Over los DoTs
   siguen haciendo daño, metiendo `take_damage`, `draw_shake`, modulate flashes… sobre un juego
   congelado. Es un bug silencioso real (se verá como errores/parpadeos en pantalla de muerte).
2. Si el enemigo muere o la escena reloads mientras hay un `await` pendiente, callbacks sobre nodos
   liberados → hay que ir fortaleciendo cada `await` con `is_instance_valid(self)` (varios ya lo
   tienen, otros no).
3. Cambiar `fire_rate`Item no afecta lo ya en cola; el estado (`_can_fire`, `_invincible`) queda
   "fuera del árbol".

**Acción**: regla de proyecto — la lógica de gameplay usa `Timer` nodos o daño/clampeo en
`_physics_process(delta)`, no `await`. Los `await` de tween (UI, feedback) pueden quedarse.
Concreto:
- `player.gd`: `_fire_cooldown: float` restado en `_physics_process`.
- DoT en `enemy.gd`: un `StatusEffect` con timer/accumulador (mismo patrón que ya usa `_slow_timer`,
  que ES el patrón correcto: repetir eso para burn/poison).
- Cada animación de invuln = un `Timer` de blink con `tick`.

### 3.5 🟠 Acoplamiento líneas arriba-abajo frágil
- `get_tree().current_scene.has_method("add_shake")` desde player y enemy: si un día el Main se
  re-nombra o se instancia distinto, se rompe en silencio. → EventBus + componente de cámara.
- `hud.gd` lee 8 propiedades del player directamente y maquilla colores por `match damage_type`
  (los colores de elemento están duplicados en **enemy.gd, hud.gd, tear.gd, minimap.gd**; cambia el
  veneno en uno solo y ya quedan dos verdes distintos).
  → Colores de elemento a `game_constants.gd` (dict `ELEMENT_COLORS`), señales que ya brinden el dato
  (`damage_type_changed(type)`).
- `player._on_hurtbox_area_entered` hace `area.get_parent()` para sacar al enemigo: frágil. Mejor el
  hitbox area belongs al enemigo y expone `owner_enemy`, o resolver via grupos + `get_contact_damage`.
- `main.gd._on_room_door_entered()`: 60 líneas de `elif` por dirección con el mismo cálculo interno
  repetido 4 veces. → tabla `DIRECTION_VECTORS` (ya existe en `level_generator.gd`, DRY) + una sola
  rama.

### 3.6 🟠 Generación de niveles decente pero mejorada
- `_count_adjacent_rooms(next_pos) > 1: continue` → el mapa SIEMPRE es un árbol (decoración "caminos
  únicos"). Solo 2 salidas entre salas = jugabilidad más lineal y menos interesante que en Isaac. Con
  permitir ~10-15% de loops el mapa gana mucha vida.
- El `while` puede teóricamente quedarse corto (si el queue se agota temprano) — loguear
  `generated.count != num_rooms` para saberlo.
- No hay control de dificultad por distancia al boss: hoy cual sala normal puede ser fácil/esclavada
  igual en cualquier lado. Clásym: `enemy_tier = f(distancia_manhattan_al_spawn)`.
- Falta semilla explicita (`seed`) para poder reproducir demos y comparar partidas (fundamental para
  iterar de diseño).

### 3.7 🟠 Combate: bugs detectados
- `enemy_tear.gd._on_body_entered` **no distingue a quién golpea**: cualquier body con `take_damage`
  recibe daño (p.ej. **balas enemigas dañan a otros enemigos** por friendly-fire involuntario, o el
  player en chain reactions raras). Debe verificar `body.is_in_group("player")`.
- `tear.gd` de player: si el enemigo muere al golpear y el tear tiene `split_on_hit`, se spawnean hijos
  desde `get_parent().call_deferred` — bien, pero `_hit_enemies` contiene references muertas (fuga
  menor, limpiarlas).
- `boss.gd`: `take_damage(...)` hace `health_updated.emit(current_health, max_health)` **aunque el
  daño no se aplique**? — realmente funciona pero por cantidad: boss no filtra iframes de invulnerabilidad
  (no aplica a él). Correcto pero documentarlo.
- La invulnerabilidad del player tras `take_damage` hace `await ... .timeout` con `process_always=true`
  default — bajo pausa (game over) el timer sigue y el `while _invincible` de blink sigue iterando el
  `modulate.a` de un player que está en una escena congelada.

### 3.8 🟡 UI: cosas razonables + deuda
- El minimapa redibuja **cada frame** (`_process` → `queue_redraw()`) por el pulso. Con 8 salas no
  importa; con 100 sí. Solución barata: solo redibujar cada 0.1 s (acumular delta) o animar el pulso con
  shader/tween.
- Los íconos con emoji (`✦`, `💎`, `💀`, `🔥`) dependen de la fuente del sistema: en Windows/consola
  está bien, en export a otros OS se ven sumamente distintos o escupe tofu (□). Rotular iconitos de
  pixel art del propio `assets/ui/`.
- `hud.tscn` usa rutas de nodos hardcodeadas (nombres con Container/MarginContainer anidados); si el
  layout se mueve medio milímetro, `hud.gd` rompe. Mantener ojo.

### 3.9 🟡 Sistema de stats del player no robusto
- `player.gd` ya es berrete de responsabilidades: input, animación, disparo, stats, inventario
  (pierce/split/explode), economía, daño/IFrames, señales. Un `PlayerStats` como `Resource` con
  `base_stats` + `modifiers: Array[ItemDef]` aislaría el gameplay de la presentación y**lo que haría
  que agregar item nuevo sea un `.tres`**, no tocar 3 scripts.
- `_get_axis()` con `AxisState` está bien implementado (grip de dirección), pero toda la parte input se
  puede simplificar con `Input.get_vector("move_left","move_right","move_up","move_down")` nativo
  (además auto-deadzone y soportaría gamepad de gratis — el project.godot solo tiene teclado+mouse).

### 3.10 🟢 Estilo de código
- Mezcla de español/inglés en nombres (`imtemto`, `caminaconchuda` vs `take_damage`) — aceptable
  prototipo, definir convención: **código en inglés, arte/locales en español**.
- Falta tipado fuerte en varias funciones (`setup_room(data)` sin tipo, `room_type: int` en vez de
  `GameConstants.RoomType`). Godot 4 con el enum del preload hace esto más agradable:
  usar `RoomType` con `const RoomType = preload(...).RoomType` en la cabecera de cada script.
- Comentarios de buena calidad en los puntos importantes — mantener esa disciplina.

---

## 4. Hallazgos — Gameplay/Diseño (lo que hará que la demo se sienta juego)

1. **No hay audio NINGUNO.** Es el gap #1 en percepción de calidad. Antes de pensar en "sintetizado
   procedural" (roadmap), poner 3-4 SFX de un pack libre y música de fondo. 90% del "se siente vivo"
   es eso.
2. **Salas de combate con solo 2 layouts**, y no se registran los ya vistos: la sensación de
   repetición es alta. Poner los `ROOM_LAYOUTS` en recursos Data (o un dict por dificultad) y añadir 4-6
   más es barato y no toca lógica.
3. **No hay progresión de pisos.** El "victoria" actual tras el boss es demo-mortal. Al menos
   "boss → portal → piso 2 con stats base +40% de dificultar" para que el loop convida a "una más".
4. **No hay gamepad** (ni acciones alternativas: WASD solo). Isaac esta pensado para gamepad; solo
   añadir input actions resolvería (bind arrows/espacio/enter al con `Input.get_vector` ya incluido).
5. **El boss no se mueve** (bug de copia/pega en `_physics_process`), y sus ataques no tienen
   telegraph (mientras carga, glow el boss 0.3 s antes de disparar) — es fácil y hace el combate justo.
6. **No hay feedback de daño crítico para el jugador** (vineta roja, slow-mo 0.1 s al morir, hit stop):
   en TODO ya lo están considerandod, es correcto.
7. Dificultad no escala con elems: con cadena de electric + explosion on kill el juego se limpia solo;
   bien para probar builds, pero al hacer demo real conviene una cuenta de poder (más adelante).

---

## 5. Plan por etapas — "demos"

El espíritu: **cada etapa es una demo descargable, coherente, jugable de punta a punta.** Nada de
añadir features al prototipo sin cerrar la que esté abierta.

### 🎯 Demo 0.1 — "Core Loop sólido" (higiene técnica, 1-2 semanas de sesiones cortas)
No añade una sola feature. Deja el terreno preparado:
- [ ] Commit del reorganizado `src/`, limpiar git, `main` en verde (2.1)
- [ ] `.gdignore` en carpetas crudas + estructura `assets/` / `art_src/` (2.2)
- [ ] Renderer `gl_compatibility`, quitar Jolt, layers de physics con nombre (2.3)
- [ ] Fix `create_timer` bajo pausa (bug de DoT game over) (3.4)
- [ ] Fix friendly-fire de `enemy_tear` (3.7)
- [ ] Fix boss `_physics_process` + telegraph básico de ataques (5)
- [ ] Autoload mínimos: `Events` (bus) y reemplazar los `current_scene.has_method` (2.4)
- [ ] SFX básicos (disparo, hit, muerte, recoger) + 1 loop de música (5.1)
- [ ] Export Windows + Release GitHub "Demo 0.1" (2.5)

### 🎯 Demo 0.2 — "Subir al Piso 2"
- [ ] `ItemDef` como Resource + migrar items existentes (3.2) ← la gran refactor
- [ ] `PlayerStats` Resource, HUD leyendo desde señales del stats (3.9)
- [ ] Piso 2: transición, generación de dificultad por distancia (3.6), boss nuevo o re-skin
- [ ] Menu principal + pausa + gamepad + opciones mínimas (volumen) (5.4)
- [ ] 4-6 layouts nuevos de sala (5.2)
- [ ] DoT/burn/poison ya en `StatusEffect` (acabar con sees de `await` de lógica) (3.4)

### 🎯 Demo 0.3 — "Contenido + identidad"
- [ ] 2-3 tipos de enemigos nuevos (con patrones distintos, no reskins)
- [ ] Sala secreta + interactuables, mini-documentos de item pool por piso
- [ ] Guardar mejores runs (muertes, pisos) — incluso un simple JSON
- [ ] Música 2-3 tracks, SFX completo, iconos pixel-art sustituyendo los emojis (3.8)
- [ ] Title screen con arte propio, resolución de identidad visual

### 🎯 Demo 0.4 → "Beta demo"
- Ud a definir según lo que diga el feedback de 0.1-0.3. Regla: **la demo manda**.

---

## 6. Reglas de proyecto (peguen esto en el README)

1. La lógica de gameplay **no usa `await`** para cooldowns/DoT/Timers de gameplay.
2. Todo **número de balance va a constantes** (o Resources) — nada de números mágicos sueltos.
3. Entre sistemas: **señales**, no métodos cruseados por `get_node`/`get_parent`.
4. Colores/textos de elementos/estados viven **en un solo lugar**.
5. Cada PR/commit: si toca un script, comprobar que **no se dupliquen patrones** ya existentes.
6. La demo se termina **no cuando se añade la feature X** sino cuando **está exportada y testada**.

---

*Auditado el 2026-10-19. Los números de sección (2.1, 3.4…) son referencias para los checks de arriba.*
