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
