#!/usr/bin/env python3
"""Generador de SFX sintetizados para el juego (Demo 0.1).

Crea los .wav en assets/audio/. Se guardo el script en el repo para que los
SFX sean reproducibles/regenerables (guia del proyecto: todo lo generado
tiene que poder recrearse; la fuente del sonido es codigo versionado).

Uso: python scripts/generate_sfx.py
"""
import math
import os
import random
import struct
import wave

SR = 44100  # sample rate


def _write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        ))
    print(f"ok {path} ({len(samples)/SR:.3f}s)")


def env(i, n, attack=0.01, release=0.3):
    """Envelope ADSR simplificado: ataque rapido, caida exponencial."""
    t = i / SR
    a = min(1.0, t / max(attack, 1e-4))
    r = math.exp(-t / (release * (n / SR)))
    return a * r


def tone(dur, f0, f1=None, wave_fn=math.sin, release=0.2):
    n = int(SR * dur)
    f1 = f1 if f1 is not None else f0
    out = []
    phase = 0.0
    for i in range(n):
        k = i / n
        freq = f0 * (f1 / f0) ** k  # interpolacion exponencial
        phase += 2 * math.pi * freq / SR
        out.append(wave_fn(phase) * env(i, n, release=release) * 0.5)
    return out


def noise(dur, release=0.1, lowpass=0.0):
    random.seed(42)  # reproducible
    n = int(SR * dur)
    out, prev = [], 0.0
    for i in range(n):
        s = random.uniform(-1, 1)
        s = prev + lowpass * (s - prev)  # filtro simple
        prev = s
        out.append(s * env(i, n, release=release) * 0.6)
    return out


def mix(*layers):
    n = max(len(x) for x in layers)
    out = [0.0] * n
    for x in layers:
        for i, s in enumerate(x):
            out[i] += s
    return out


def main():
    out_dir = "assets/audio"
    # Disparo: blip descendente con cuerpo
    _write_wav(f"{out_dir}/shoot.wav",
               mix(tone(0.10, 900, 260, release=0.06),
                   tone(0.06, 1800, 900, wave_fn=math.sin, release=0.03)))
    # Impacto: click oscuro
    _write_wav(f"{out_dir}/hit.wav", mix(noise(0.07, release=0.035, lowpass=0.35)))
    # Muerte de enemigo: barrido descendente + chispa
    _write_wav(f"{out_dir}/enemy_die.wav",
               mix(tone(0.32, 520, 90, release=0.14),
                   noise(0.14, release=0.07, lowpass=0.5)))
    # Pickup de cristal: arpegio ascendente brillante
    _write_wav(f"{out_dir}/pickup.wav",
               mix(tone(0.09, 880, 880, release=0.08),
                   [0.0] * int(SR * 0.045) + tone(0.11, 1320, 1320, release=0.09),
                   [0.0] * int(SR * 0.09) + tone(0.13, 1760, 1760, release=0.10)))
    # Dano al jugador: zumbido grave
    _write_wav(f"{out_dir}/player_hurt.wav",
               mix(tone(0.22, 220, 120, release=0.10), noise(0.10, release=0.05, lowpass=0.25)))
    # Explosion: golpe + rugido filtrado
    _write_wav(f"{out_dir}/explosion.wav",
               mix(noise(0.45, release=0.18, lowpass=0.12),
                   tone(0.25, 140, 50, release=0.16)))


if __name__ == "__main__":
    main()
