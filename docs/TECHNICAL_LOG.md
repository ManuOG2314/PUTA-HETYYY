# 🛠️ LOG TÉCNICO — Registro de cambios de desarrollo

> Documento vivo: cada bloque se añade **al estar terminado** el trabajo que describe.
> Formato: fecha · tarea · archivos tocados · decisión técnica tomada y por qué.
> Contexto y hallazgos completos: ver [AUDITORIA.md](AUDITORIA.md).

---

## Índice de entradas

| # | Fecha | Etapa | Titular |
|---|-------|-------|---------|
| 0 | 2026-10-19 | Demo 0.1 | Creación del log + snapshot del estado actual |
| 1 | 2026-10-19 | Demo 0.1 | Higiene de assets: `ball.png` a `assets/`, `.gdignore` en crudos |
| 2 | 2026-10-19 | Demo 0.1 | Fix bug de `create_timer` bajo pausa (DoT/drones post-Game Over) |
| 3 | 2026-10-19 | Demo 0.1 | Fix friendly-fire de proyectiles enemigos |
| 4 | 2026-10-19 | Demo 0.1 | Fix `boss.gd` (movimiento + telegraph) |
| 5 | 2026-10-19 | Demo 0.1 | Autoload `Events` (EventBus) |
| 6 | 2026-10-19 | Demo 0.1 | Autoload `Audio` + SFX sintetizados |
| 7 | 2026-10-19 | Demo 0.1 | Config de `project.godot` (renderer, capas físicas) |

---

## Entrada 0 — 2026-10-19 · Creación del log + snapshot del estado

**Etapa**: Demo 0.1 (higiene técnica)

**Qué se hizo**:
- Auditoría completa del código → `docs/AUDITORIA.md`.
- Commit inicial ("snapshot") del estado actual del repo, que estaba en riesgo:
  la reorganización a `src/` nunca se había commiteado (archivos viejos en la raíz
  borrados en el working tree pero el último commit aún apuntaba al layout raíz).
- Creación de este log técnico.

**Archivos**: `docs/AUDITORIA.md`, `docs/TECHNICAL_LOG.md`, todo el snapshot.

**Decisión**: commitear TODO el estado transitorio de una vez (git add -A) para que
el repo vuelva a ser "clonable y jugable" antes de tocar nada más. A partir de aquí,
commits pequeños por tarea.

**Commit**: ver `git log` (referencia con el título de la entrada).

---

## Entrada 1 — 2026-10-19 · Higiene de assets

**Etapa**: Demo 0.1 (higiene técnica) · Ref AUDITORIA.md §2.2

**Qué se hizo**:
- `FS/ball.png` (el orbe usado como textura de lágrimas, proyectiles enemigos,
  explosiones, cristales y pedestales) movido a `assets/orb/ball.png` junto con
  su `.import` (se conserva el UID `uid://bg5sduq4vsxkb`, así las escenas siguen
  resolviendo la textura por UID sin reimportar).
- Referencias actualizadas: `src/combat/enemy_tear.tscn`, `src/combat/explosion.tscn`,
  `src/items/crystal_pickup.tscn`, `src/items/item_pedestal.gd`.
- `.gdignore` añadido en las carpetas de material crudo para que Godot deje de
  importarlas: `FS/`, `"assets que consegui porai"`, `FS/raw_assets/`.
- Borrados los `.import` huérfanos que Godot había generado dentro de esas carpetas
  (duplicando texturas ya importadas en `assets/`).

**Decisión**: el nombre del archivo sigue siendo `ball.png` (no se renombra aún) para
no invalidar UIDs; renombrado semántico (p. ej. `orb.png`) queda pendiente para la
entrada que cree el item/asset system.

**Verificación**: grep por `res://FS/` solo queda en archivos `.gdignore`-ados (no
importados); las 4 referencias en código/escenas apuntan a `res://assets/orb/ball.png`.

---

## Entrada 2 — 2026-10-19 · Fix `create_timer` bajo pausa

**Etapa**: Demo 0.1 (fixes) · Ref AUDITORIA.md §3.4

**Problema**: `get_tree().create_timer(...)` por defecto corre SIEMPRE
(`process_always = true`). Al hacer Game Over / Victoria (`get_tree().paused = true`),
los timers de lógica de gameplay seguían corriendo: los DoTs (burn/poison) seguían
aplicando daño a enemigos muertos o al player, la cadencia de disparo daba reset
durante la pausa, y el blink de invulnerabilidad seguía modificando `modulate.a`
sobre el juego congelado.

**Qué se hizo**: en todos los timers usados como lógica de gameplay se pasa
`process_always = false` para que se congelen con el árbol en pausa:
- `player.gd`: cadencia de disparo (`fire_rate`), invulnerabilidad, blink.
- `enemy.gd`: burn loop, poison loop, flash de hit.
- `enemy_ranged.gd`: cooldown de disparo.
- `boss.gd`: ráfagas y espiral.
- `item_pedestal.gd`: advertencia de "faltan cristales".

**Decisión**: se eligió esta solución mínima en lugar de migrar ya a nodos `Timer`
porque la migración completa de cooldowns a `_physics_process` está planificada
para Demo 0.2 (junto al refactor de `PlayerStats`). El parámetro `process_always`
es el fix correcto y barato para el bug real.

**Nota**: sigue en deuda (Demo 0.2) la regla del proyecto "la lógica no usa `await`"
ver §6 de la auditoría.

---

## Entrada 3 — 2026-10-19 · Fix friendly-fire enemigo

**Etapa**: Demo 0.1 (fixes) · Ref AUDITORIA.md §3.7

**Problema**: `src/combat/enemy_tear.gd::_on_body_entered` dañaba a **cualquier**
nodo que tuviera `take_damage`. Como los enemigos y el player tienen ese método,
las balas enemigas dañaban a otros enemigos (y en cascada, con el boss pegándose
a sí mismo con su propia espiral si el disparo reentraba).

**Archivo**: `src/combat/enemy_tear.gd`.

**Fix**: el proyectil enemigo ahora solo daña cuerpos del grupo `"player"`
(el grupo resto lo rechaza sin consumir el proyectil, salvo que sea muro →
`queue_free()` vía señal de `_on_body_entered` con cuerpo no-player).

---

## Entrada 4 — 2026-10-19 · Fix `boss.gd` (movimiento + telegraph)

**Etapa**: Demo 0.1 (fixes) · Ref AUDITORIA.md §3.3/§5

**Problema**: `_physics_process` de `boss.gd` era una copia del template del
`Enemy` base que rompió al quedar "a medio terminar": el jefe **nunca se movía**
(siempre `velocity = 0` salvo knockback) y no usaba `_animate_sprite`.

**Qué se hizo**:
- Reescrito `_physics_process`: el boss ahora hace knockback con la misma fórmula
  que la base, y **deriva lentamente hacia el player** (drift, 40 px/s, congelado
  si el target no existe). Justifico el drift en el combat design del boss: hoy el
  boss es puramente un "turret" y el jugador aprende a posicionarse inactivo;
  con drift leve el combate obliga a reeducarse.
- Añadido **telegraph básico**: al preparar un ataque, un rápido destello blanco
  (tween de modulate) avisa de la ráfaga/ring/spiral antes de ejecutarla.
  Hace el combate justo (regla del diseño: toda amenaza hay que poder verte venir).
- Timers internos (ráfaga/spiral) usan `process_always = false` (ver Entrada 2).

**Deuda registada (Demo 0.2)**: el `match` de modulate por estado del boss sigue
duplicado respecto a `Enemy` (aunque con su color propio); se consolidará cuando
los estados enemigos vayan a una máquina de estados con `UpdateVisuals`.

---

## Entrada 5 — 2026-10-19 · Autoload `Events` (EventBus)

**Etapa**: Demo 0.1 (arquitectura) · Ref AUDITORIA.md §2.4

**Nuevo archivo**: `src/core/events.gd` (autoload `Events`).

**Responsabilidad**: bus de señales global. Regla nueva del proyecto: los sistemas
no se hablan por `get_tree().current_scene.has_method(...)` ni `get_parent()`.

**Qué se reemplazó**:
- `player.gd::take_damage` y `enemy.gd::take_damage` emitían shake haceindo
  `get_tree().current_scene.has_method("add_shake")` → ahora emiten
  `Events.shake_requested.emit(intensidad, duracion)`.
- `main.gd::_ready()` conecta `Events.shake_requested` a su `add_shake()`
  (único dueno de la cámara; sin cambios de comportamiento).
- Señales cosméticas añadidas al bus para el audio: `shoot_sfx`, `hit_sfx`,
  `pickup_sfx`, `player_hurt_sfx`, `enemy_died_sfx`, `explosion_sfx`.

**Emisores conectados**:
- `player.gd`: dispara → `shoot_sfx`; recibe daño → `shake` + `player_hurt_sfx`.
- `enemy.gd`: recibe hit → `hit_sfx` (+shake); muere → `enemy_died_sfx`;
  explosión on-kill → `explosion_sfx`.
- `crystal_pickup.gd`: recoger → `pickup_sfx`.

**Deuda registada (Demo 0.2)**: añadir más señales de juego (room_cleared, run_won,
damage_type_changed) para poder desacoplar HUD del player (§3.5).

---

## Entrada 6 — 2026-10-19 · Autoload `Audio` + SFX sintetizados

**Etapa**: Demo 0.1 (audio) · Ref AUDITORIA.md §5.1

**Nuevos archivos**:
- `src/core/audio.gd` (autoload `Audio`): pool de 8 `AudioStreamPlayer`
  reutilizables + dict `SFX_PATHS` (nombre → ruta) + caché lazy `load()`
  (no `preload`, para no romper el parseo del primer escaneo headless de Godot).
  Los eventos cosméticos de `Events` se conectan a su sonido correspondiente en
  `Audio._ready()`: el gameplay no sabe qué archivo suena.
- `scripts/generate_sfx.py`: generador reproducible de los 6 SFX (ondas seno /
  ruido con envolventes y filtros simples, PCM16 44100 Hz). Los .wav son
  generados, no grabados: la fuente del sonido queda versionada como código.
- `assets/audio/`: `shoot.wav`, `hit.wav`, `enemy_die.wav`, `pickup.wav`,
  `player_hurt.wav`, `explosion.wav`.

**Volumen por superficie**: los handlers de `Events` bajan entre -2 y -6 dB
(los .wav se generan a ~50% de amplitud; el bus Master queda "apto para música"
futura vía buses `SFX`/`Music` — pendiente Demo 0.2).

**Decisión**: empezar con SFX sintetizados en vez de pack externo para la demo
(toque propio + 0 MB de licencia pendiente). Si en Demo 0.2 se decide ir por un
pack (por ejemplo Sons of Skart/Sonniss), `audio.gd` permite cambiar el dict sin
tocar gameplay.

---

## Entrada 7 — 2026-10-19 · Config de `project.godot`

**Etapa**: Demo 0.1 (config) · Ref AUDITORIA.md §2.3

**Cambios**:
1. Autoloads registrados: `Events`, `Audio` (Entradas 5 y 6).
2. `renderer/rendering_method="mobile"` → `"gl_compatibility"` (juego 2D
   pixel-art en PC: backend más estable y eficiente para 2D; "mobile" era una
   config de prototipo). También eliminado `rendering_device/driver.windows`
   (solo aplica a renderers RD; era ruido).
3. Quito `3d/physics_engine="Jolt Physics"` (juego 2D, configuración muerta).
4. `layer_names`: añadidos los 4 layers de `2d_physics` con los mismos nombres
   que los de render (Player/Walls/Enemies/Tears). Los .tscn siguen usando
   números en crudo (mask 13, etc.); migrarlos a nombres es deuda de Demo 0.2.

**Verificación**: `--headless --import` sin errores y smoke test
`--headless --quit-after 600` (juego realmente ejecutando el loop: generación,
spawn, combate simulado sin input) **sin un solo ERROR/WARNING en salida**.

**Nota**: el executale del check es `Godot_v4.7-stable_win64_console.exe`
(desktop de este equipo). Anotado como comando estándar del proyecto:
```
"c:\...\Godot_v4.7-stable_win64_console.exe" --headless --path . --import
"--..." --headless --path . --quit-after 600   # smoke test
```

