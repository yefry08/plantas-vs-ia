# Plantas vs IA

**Jugar en el navegador:** https://yefry08.github.io/plantas-vs-ia/

Tower defense por carriles hecho en **Godot 4 (GDScript)**, jugable en el navegador.
Las plantas defienden el jardín de oleadas de **robots IA** (todos son parodias originales,
sin logos ni marcas). Una **IA aliada** te ayuda a cambio de **tokens** (moneda simbólica del juego).

- 5 carriles × 9 columnas, energía solar, podadora de emergencia por carril, pala, pausa y velocidad ×2.
- 14 plantas, 15 robots (4 tiers + jefe), 5 cartas de IA aliada.
- Campaña de 21 niveles en 4 zonas + el jefe final **La AGI** (3 fases, 2 finales).
- Arte 100 % procedural (formas vectoriales, caras tipo emoji dibujadas) y sonidos sintetizados: **cero assets de terceros**.
- Todo el contenido es data-driven en archivos `.tres`.
- Progreso guardado en `user://` (en web se guarda en IndexedDB del navegador).

## Cómo jugar

| Acción | Ratón / toque | Teclado (opcional) |
|---|---|---|
| Elegir planta | Toca su carta arriba | `1`–`6` |
| Plantar | Toca una casilla | |
| Recoger energía / tokens | Toca el sol que cae | |
| Usar carta de IA | Toca la carta y luego un robot | `Q`, `W` |
| Pala | Toca la pala y luego una planta | `S` |
| Cancelar selección | Clic derecho | `Esc` |
| Pausa / velocidad ×2 | Botones `II` y `x1` | `Esc`/`P`, `F` |

Se puede jugar de principio a fin solo con ratón o con toque en móvil.

### Cartas de IA aliada

| Carta | Tokens | Efecto |
|---|---|---|
| Autodestrucción | 3 | El robot explota y daña 3×3 |
| Botón de Apagado | 4 | Apaga al robot 10 s |
| Apagado en Cadena | 6 | Apaga a todo su carril 8 s |
| Alineamiento | 8 | El robot se vuelve aliado 15 s |
| Red Team | 5 | Revela habilidades, debilidades e ilusiones; −25 % defensa 10 s |

Resistencias: Mythos es inmune a Autodestrucción; apagar a Astra cuesta el doble; la AGI solo
acepta Alineamiento en su fase 3 (3 cartas = final **"AGI alineada"**).

## Ejecutar en local

1. Instala **Godot 4.3 o superior** (probado con 4.7.2).
2. Abre `project.godot` en el editor y pulsa **F5**.

Desde la terminal:

```bash
godot --path .
```

## Balance (sin tocar código)

Todo el balance vive en `data/`:

- `data/plants/*.tres` — coste, recarga, vida, daño, intervalos, efectos.
- `data/robots/*.tres` — vida, escudo, velocidad, mordida, tokens, resistencias, reglas de cartas y `params` de cada habilidad.
- `data/cards/*.tres` — coste en tokens, recarga, duración, potencia.
- `data/levels/level_XX.tres` — carriles activos, energía/tokens iniciales, sol del cielo, oleadas (`WaveData`), premio y tutorial.

Ábrelos en el Inspector de Godot o edítalos como texto.
`tools/generate_content.gd` es el generador inicial; **sobrescribe `data/`** si lo vuelves a ejecutar:

```bash
godot --headless --path . --script res://tools/generate_content.gd
```

## Pruebas automáticas

```bash
# Compila todos los scripts y carga todos los niveles
godot --headless --path . -- --check-scripts

# Juega un nivel sola ("chaos" = planta de todo y usa todas las cartas; "fair" = bot sencillo con el progreso real)
godot --headless --path . -- --autotest=5 --time=300 --speed=8 --mode=fair

# Final alternativo del jefe
godot --headless --path . -- --autotest=21 --ending=aligned
```

El modo autotest no toca tu partida guardada.

## Exportar para web

Requisitos del proyecto (ya configurados): renderer **Compatibility**, preset **Web** con
**Thread Support desactivado** (funciona en itch.io y GitHub Pages sin cabeceras COOP/COEP),
resolución 1280×720, stretch `canvas_items` / `keep`.

1. Instala las plantillas de exportación: en Godot, **Editor → Manage Export Templates → Download and Install**.
2. Exporta:
   ```bash
   godot --headless --path . --export-release "Web" build/web/index.html
   ```
   o desde **Project → Export → Web → Export Project**.
3. Prueba en local (el navegador no carga `file://`):
   ```bash
   python -m http.server 8000 --directory build/web
   ```
   y abre <http://localhost:8000>.

## Publicar en itch.io

1. Comprime **el contenido** de `build/web/` (no la carpeta) en un `.zip`; `index.html` debe quedar en la raíz del zip.
2. En itch.io: **Upload new project** → *Kind of project*: **HTML**.
3. Sube el zip y marca **This file will be played in the browser**.
4. *Embed options*: tamaño **1280 × 720**, activa **Mobile friendly** y **Fullscreen button**.
5. *SharedArrayBuffer support*: **déjalo desactivado** (la exportación no usa hilos).
6. Guarda, revisa la vista previa y publica.

### GitHub Pages (alternativa)

Sube el contenido de `build/web/` a una rama `gh-pages` (o a `/docs`) y activa Pages en los ajustes del repositorio.
Al no usar hilos, no hacen falta cabeceras especiales.

## Estructura

```
scenes/            main_menu, level_select, seed_select, level, credits
scripts/autoload/  GameState (recursos, progreso), SaveManager, AudioManager
scripts/data/      PlantData, RobotData, CardData, WaveData, LevelData (Resources)
scripts/components HealthComponent, StatusEffectComponent, HitboxComponent
scripts/game/      Level, LaneManager, WaveManager, HUD, Projectile, Pickup, Mower, FX, Tutorial
scripts/plants/    Plant (base) + shooter, producer, trap, emp, lightning, mine
scripts/robots/    Robot (base) + una clase por habilidad + boss_agi
scripts/ui/        menús, cartas, contadores, IA aliada, barra del jefe
scripts/art/       Art: todo el dibujo procedural
data/              contenido .tres
tools/             generador de contenido
```

Señales desacopladas en `GameState`: `robot_died`, `tokens_changed`, `sun_changed`, `plant_placed`, `card_used`...

## Créditos y aviso

Juego original. Todos los robots son parodias con nombres propios; no se usa ningún logo,
marca, sprite ni sonido de terceros. Los tokens son una moneda simbólica dentro del juego.
