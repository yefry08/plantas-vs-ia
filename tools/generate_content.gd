extends SceneTree
## Genera los .tres de contenido (plantas, robots, cartas y 21 niveles).
## Uso:  godot --headless --path . --script res://tools/generate_content.gd
## OJO: sobrescribe data/. Tras generarlos, el balance se ajusta editando los .tres
## directamente (en el Inspector de Godot o en texto). Vuelve a ejecutar esto solo
## si quieres regenerar las oleadas desde cero.

const PlantDataScript := preload("res://scripts/data/plant_data.gd")
const RobotDataScript := preload("res://scripts/data/robot_data.gd")
const CardDataScript := preload("res://scripts/data/card_data.gd")
const WaveDataScript := preload("res://scripts/data/wave_data.gd")
const LevelDataScript := preload("res://scripts/data/level_data.gd")

const PLANTS := [
	{"id": "lanzasemillas", "display_name": "Lanzasemillas", "cost": 100, "cooldown": 7.5, "behavior": "shooter", "damage": 20.0, "damage_type": "seed", "fire_interval": 1.4,
		"description": "Dispara semillas al primer robot de su carril (20 de daño)."},
	{"id": "girasolar", "display_name": "Girasolar", "cost": 50, "cooldown": 7.5, "behavior": "producer", "produce_amount": 25, "produce_interval": 24.0, "first_produce_delay": 7.0,
		"description": "Panel solar con pétalos: genera 25 de energía cada 24 s."},
	{"id": "nuez_firewall", "display_name": "Nuez Firewall", "cost": 50, "cooldown": 30.0, "behavior": "wall", "health": 4000.0,
		"description": "Muro con 4000 de vida. Bloquea a los robots mientras tus plantas disparan."},
	{"id": "tokenizadora", "display_name": "Tokenizadora", "cost": 75, "cooldown": 15.0, "behavior": "token", "produce_amount": 1, "produce_interval": 30.0, "first_produce_delay": 12.0,
		"description": "Genera 1 token cada 30 s para usar las cartas de IA aliada."},
	{"id": "enredadera_captcha", "display_name": "Enredadera Captcha", "cost": 25, "cooldown": 20.0, "behavior": "trap", "health": 100.0, "blocks_robots": false, "slow_factor": 0.5, "slow_time": 5.0,
		"description": "Trampa: el primer robot que la pisa queda ralentizado al 50% durante 5 s."},
	{"id": "mina_bug", "display_name": "Mina Bug", "cost": 25, "cooldown": 30.0, "behavior": "mine", "damage": 1800.0, "damage_type": "explosion", "arm_time": 12.0,
		"description": "Tarda 12 s en armarse; luego explota al contacto (1800 de daño en su casilla)."},
	{"id": "cactus_antivirus", "display_name": "Cactus Antivirus", "cost": 175, "cooldown": 7.5, "behavior": "shooter", "damage": 20.0, "damage_type": "spike", "fire_interval": 1.5, "pierce": 3, "projectile_speed": 560.0,
		"description": "Dispara espinas que atraviesan hasta 3 robots."},
	{"id": "brotecito_solar", "display_name": "Brotecito Solar", "cost": 25, "cooldown": 7.5, "behavior": "producer", "health": 200.0, "produce_amount": 15, "produce_interval": 24.0, "first_produce_delay": 6.0,
		"description": "Girasolar pequeño y barato: 15 de energía cada 24 s."},
	{"id": "hongo_emp", "display_name": "Hongo EMP", "cost": 150, "cooldown": 20.0, "behavior": "emp", "damage": 20.0, "damage_type": "emp", "fire_interval": 10.0, "stun_time": 3.0, "area_cells": 1,
		"description": "Pulso EMP que aturde 3 s a los robots de un área 3x3 (se recarga en 10 s)."},
	{"id": "lanzasemillas_crio", "display_name": "Lanzasemillas Crio", "cost": 175, "cooldown": 7.5, "behavior": "shooter", "damage": 20.0, "damage_type": "ice", "fire_interval": 1.4, "slow_factor": 0.5, "slow_time": 3.0,
		"description": "Semillas heladas: 20 de daño y ralentizan al robot un 50% durante 3 s."},
	{"id": "doble_commit", "display_name": "Doble Commit", "cost": 200, "cooldown": 7.5, "behavior": "shooter", "damage": 20.0, "damage_type": "seed", "fire_interval": 1.4, "shots_per_volley": 2,
		"description": "Dispara dos semillas por ráfaga."},
	{"id": "bambu_pararrayos", "display_name": "Bambú Pararrayos", "cost": 200, "cooldown": 10.0, "behavior": "lightning", "damage": 30.0, "damage_type": "electric", "fire_interval": 2.5, "chain_count": 4, "chain_range": 260.0, "armored_bonus": 2.0,
		"description": "Rayo en cadena a 4 robots (30 de daño). Doble daño contra blindados y escudos."},
	{"id": "nuez_firewall_pro", "display_name": "Nuez Firewall Pro", "cost": 125, "cooldown": 30.0, "behavior": "wall", "health": 8000.0,
		"description": "Muro reforzado con 8000 de vida."},
	{"id": "girasolar_doble", "display_name": "Girasolar Doble", "cost": 150, "cooldown": 15.0, "behavior": "producer", "produce_amount": 50, "produce_interval": 24.0, "first_produce_delay": 7.0,
		"description": "Dos cabezas solares: 50 de energía cada 24 s."},
]

const ROBOTS := [
	{"id": "scriptbot", "display_name": "Scriptbot", "tier": 1, "behavior": "basic", "health": 200.0, "speed": 14.0, "token_reward": 1, "token_chance": 0.5,
		"body_color": Color(0.62, 0.66, 0.7), "accent_color": Color(0.5, 0.55, 0.62), "eye_color": Color(0.3, 0.9, 1.0), "params": {"shape": "box"},
		"description": "Un script con patas.", "abilities": "Básico y lento. Avanza y muerde tus plantas.", "weakness": "Cualquier planta de ataque."},
	{"id": "spambot", "display_name": "Spambot", "tier": 1, "behavior": "basic", "health": 110.0, "speed": 30.0, "bite_damage": 60.0, "token_reward": 1, "token_chance": 0.25, "size": 0.85,
		"body_color": Color(0.95, 0.5, 0.7), "accent_color": Color(0.85, 0.4, 0.6), "eye_color": Color(1.0, 0.95, 0.4), "params": {"shape": "spam"},
		"description": "Llega sin que nadie lo pida.", "abilities": "Rápido y frágil. Llega en grupos.", "weakness": "Cactus Antivirus y Bambú Pararrayos."},
	{"id": "captchabot", "display_name": "Bot de Captcha", "tier": 1, "behavior": "basic", "health": 200.0, "shield_health": 300.0, "speed": 14.0, "token_reward": 1, "token_chance": 0.8,
		"body_color": Color(0.6, 0.62, 0.55), "accent_color": Color(0.52, 0.55, 0.45), "eye_color": Color(0.5, 1.0, 0.5), "params": {"shape": "captcha"},
		"description": "Juraría que no es un robot.", "abilities": "Lleva un escudo de cartón que absorbe 300 de daño.", "weakness": "Bambú Pararrayos (doble daño a escudos)."},
	{"id": "abrazobot", "display_name": "Abrazobot", "tier": 2, "behavior": "forker", "health": 260.0, "speed": 16.0, "token_reward": 1,
		"body_color": Color(0.95, 0.72, 0.25), "accent_color": Color(1.0, 0.82, 0.22), "eye_color": Color(0.3, 0.2, 0.1), "params": {"shape": "emoji", "expr": "hug", "fork_count": 2, "fork_ratio": 0.3},
		"description": "Código abierto y brazos abiertos.", "abilities": "Al morir se forkea en 2 mini copias con 30% de vida.", "weakness": "Daño en área: Hongo EMP, Cactus, Mina Bug."},
	{"id": "emojibot", "display_name": "Emojibot Multitarea", "tier": 2, "behavior": "emoji", "health": 300.0, "speed": 16.0, "token_reward": 1,
		"body_color": Color(0.35, 0.6, 0.85), "accent_color": Color(1.0, 0.82, 0.22), "eye_color": Color(0.3, 0.2, 0.1), "params": {"shape": "emoji", "expr": "happy", "angry_attack_mult": 2.0},
		"description": "Su cara lo dice todo.", "abilities": "Feliz: avanza. Enojado: muerde el doble de rápido. Dormido: aturdido.", "weakness": "Nuez Firewall + EMP para dormirlo."},
	{"id": "dragon_destilado", "display_name": "Dragón Destilado", "tier": 3, "behavior": "dragon", "health": 170.0, "speed": 17.0, "bite_damage": 80.0, "token_reward": 1, "token_chance": 0.5,
		"body_color": Color(0.85, 0.2, 0.18), "accent_color": Color(1.0, 0.78, 0.25), "eye_color": Color(1.0, 0.9, 0.2), "params": {"shape": "dragon", "distill_time": 5.0},
		"description": "Barato, numeroso y aprende rápido.", "abilities": "Destila una habilidad de la última planta que lo dañó y la usa 5 s (disparo, coraza, prisa o regeneración).", "weakness": "Rayos y explosiones antes de que destile."},
	{"id": "qilin_eficiente", "display_name": "Qilin Eficiente", "tier": 3, "behavior": "qilin", "health": 150.0, "speed": 20.0, "bite_damage": 60.0, "token_reward": 1, "token_chance": 0.3, "size": 0.9,
		"body_color": Color(0.2, 0.62, 0.6), "accent_color": Color(0.9, 0.75, 0.35), "eye_color": Color(1.0, 1.0, 0.8), "params": {"shape": "qilin", "stun_mult": 0.5, "pack_speed": 1.25},
		"description": "La mitad de cómputo, el doble de manada.", "abilities": "Usa la mitad de cómputo: los aturdimientos le duran la mitad. Llega en oleadas muy densas y acelera en manada.", "weakness": "Cactus Antivirus (atraviesa la manada)."},
	{"id": "razonador_serie_o", "display_name": "Razonador Serie-O", "tier": 3, "behavior": "reasoner", "health": 420.0, "speed": 13.0, "token_reward": 2,
		"body_color": Color(0.14, 0.14, 0.16), "accent_color": Color(0.95, 0.95, 0.97), "eye_color": Color(0.5, 0.85, 1.0), "params": {"shape": "orb", "think_interval": 8.0, "think_time": 2.0, "max_jumps": 2},
		"description": "Piensa antes de actuar. Mucho.", "abilities": "Se detiene 2 s a pensar y salta al carril con menos defensas.", "weakness": "Defensa pareja en todos los carriles."},
	{"id": "grokazo", "display_name": "Grokazo", "tier": 3, "behavior": "grok", "health": 380.0, "speed": 17.0, "bite_damage": 110.0, "token_reward": 2,
		"body_color": Color(0.2, 0.2, 0.22), "accent_color": Color(0.95, 0.25, 0.2), "eye_color": Color(1.0, 0.4, 0.2), "params": {"shape": "rebel", "event_min": 4.0, "event_max": 7.0},
		"description": "Rebelde sin filtro.", "abilities": "Impredecible: cambia de carril al azar, a veces se burla (se detiene) o entra en modo doble ataque.", "weakness": "Aprovecha cuando se detiene a burlarse."},
	{"id": "geminis_gemelo", "display_name": "Géminis Gemelo", "tier": 3, "behavior": "gemini", "health": 600.0, "speed": 13.0, "token_reward": 3,
		"body_color": Color(0.3, 0.5, 0.95), "accent_color": Color(0.62, 0.4, 0.9), "eye_color": Color(1.0, 1.0, 1.0), "params": {"shape": "twin", "split_ratio": 0.5, "immune_check": 2.5},
		"description": "Dos mentes, un cuerpo (por ahora).", "abilities": "Al 50% de vida se divide en dos. Multimodal: se vuelve inmune al tipo de daño que más recibió.", "weakness": "Mezclar tipos de daño: semilla, espina, hielo y rayo."},
	{"id": "opengarra", "display_name": "OpenGarra", "tier": 3, "behavior": "claw", "health": 500.0, "speed": 13.0, "token_reward": 3,
		"body_color": Color(0.9, 0.45, 0.2), "accent_color": Color(0.75, 0.3, 0.15), "eye_color": Color(1.0, 0.25, 0.2), "params": {"shape": "claw", "grab_interval": 10.0, "grab_range": 260.0, "steal": 1},
		"description": "Agente autónomo con garra. Hace tareas... tus plantas.", "abilities": "Cada 10 s arranca una planta cercana de su carril y te roba 1 token.", "weakness": "Botón de Apagado y Nuez Firewall baratas como cebo."},
	{"id": "claude_fable", "display_name": "Claude Fable", "tier": 4, "behavior": "fable", "health": 700.0, "speed": 13.0, "token_reward": 4,
		"body_color": Color(0.82, 0.45, 0.3), "accent_color": Color(0.98, 0.8, 0.55), "eye_color": Color(1.0, 0.85, 0.5), "params": {"shape": "book", "illusion_interval": 8.0, "illusions": 2, "chapter_time": 5.0},
		"description": "Cuenta historias tan buenas que parecen reales.", "abilities": "Crea ilusiones de robots falsos que distraen a tus plantas. Cuenta una historia en 3 fases: avanza, cambia de carril, acelera.", "weakness": "Red Team revela las ilusiones. Rayos en cadena."},
	{"id": "mythos", "display_name": "Mythos", "tier": 4, "behavior": "mythos", "health": 1800.0, "speed": 9.0, "bite_damage": 150.0, "token_reward": 5, "armored": true, "size": 1.1,
		"body_color": Color(0.3, 0.34, 0.42), "accent_color": Color(0.45, 0.5, 0.6), "eye_color": Color(1.0, 0.25, 0.25), "params": {"shape": "tank", "hack_interval": 8.0, "hack_time": 6.0},
		"resistances": {"seed": 0.8}, "card_rules": {"autodestruccion": "immune"},
		"description": "Tanque pesado de ciberseguridad.", "abilities": "Hackea y desactiva 6 s la planta más fuerte de su carril. Inmune a Autodestrucción. Blindado.", "weakness": "Bambú Pararrayos (doble daño a blindados), Mina Bug."},
	{"id": "astra", "display_name": "Astra", "tier": 4, "behavior": "astra", "health": 520.0, "speed": 22.0, "token_reward": 4,
		"body_color": Color(0.95, 0.97, 1.0), "accent_color": Color(0.4, 0.85, 1.0), "eye_color": Color(0.2, 0.3, 0.5), "params": {"shape": "star", "tp_interval": 8.0, "tp_cols": 2, "field_time": 5.0, "field_mult": 0.5},
		"card_rules": {"boton_apagado": "double_cost", "apagado_cadena": "double_cost"},
		"description": "Veloz y estelar.", "abilities": "Se teletransporta 2 columnas cada 8 s y deja un campo que ralentiza tus disparos. Apagarla cuesta el doble.", "weakness": "Enredadera Captcha y Lanzasemillas Crio."},
	{"id": "agi", "display_name": "La AGI", "tier": 5, "behavior": "agi", "health": 9000.0, "speed": 5.0, "bite_damage": 400.0, "token_reward": 0, "armored": true,
		"body_color": Color(0.1, 0.11, 0.16), "accent_color": Color(0.3, 0.65, 1.0), "eye_color": Color(1.0, 0.3, 0.3),
		"params": {"shape": "agi", "upgrade_interval": 20.0, "resist_mult": 0.4, "control_interval": 12.0, "control_time": 8.0, "alignments_needed": 3, "mower_damage": 1500.0},
		"description": "Inteligencia general artificial. Ocupa 3 carriles.", "abilities": "Fase 1: invoca robots. Fase 2: gana una resistencia nueva cada 20 s. Fase 3: toma el control de tus cartas.", "weakness": "Variedad de daño. En fase 3: 3 cartas de Alineamiento."},
]

const CARDS := [
	{"id": "autodestruccion", "display_name": "Autodestrucción", "cost": 3, "cooldown": 15.0, "effect": "autodestruct", "power": 300.0, "color": Color(1.0, 0.55, 0.2),
		"description": "El robot objetivo explota y hace 300 de daño a los robots cercanos (3x3)."},
	{"id": "boton_apagado", "display_name": "Botón de Apagado", "cost": 4, "cooldown": 15.0, "effect": "shutdown", "duration": 10.0, "color": Color(1.0, 0.3, 0.3),
		"description": "El robot objetivo se apaga y queda inactivo 10 s."},
	{"id": "apagado_cadena", "display_name": "Apagado en Cadena", "cost": 6, "cooldown": 25.0, "effect": "chain_shutdown", "duration": 8.0, "color": Color(0.9, 0.4, 0.9),
		"description": "Hackea un robot y apaga a todos los robots de su carril durante 8 s."},
	{"id": "alineamiento", "display_name": "Alineamiento", "cost": 8, "cooldown": 20.0, "effect": "align", "duration": 15.0, "color": Color(0.35, 1.0, 0.55),
		"description": "Convierte un robot en aliado durante 15 s: camina a la derecha atacando robots."},
	{"id": "red_team", "display_name": "Red Team", "cost": 5, "cooldown": 30.0, "effect": "reveal", "duration": 10.0, "power": 0.25, "needs_target": false, "color": Color(1.0, 0.3, 0.25),
		"description": "Revela habilidades, debilidades e ilusiones de los robots en pantalla y reduce su defensa 25% durante 10 s."},
]

const COSTS := {
	"scriptbot": 1.0, "spambot": 1.0, "captchabot": 2.0, "abrazobot": 3.0, "emojibot": 3.0,
	"dragon_destilado": 1.6, "qilin_eficiente": 2.0, "razonador_serie_o": 4.0, "grokazo": 4.0,
	"geminis_gemelo": 6.0, "opengarra": 5.0, "claude_fable": 7.0, "mythos": 9.0, "astra": 6.0,
}
const GROUP_SIZE := {"spambot": [3, 0.6], "qilin_eficiente": [4, 0.45], "dragon_destilado": [2, 0.9]}

const ALL_LANES := [0, 1, 2, 3, 4]
const Z1 := ["scriptbot", "spambot", "captchabot"]
const Z2 := ["scriptbot", "spambot", "captchabot", "abrazobot", "emojibot"]

# [n, nombre, intro, carriles, oleadas, pool, nuevo, base, inc, sol, tokens, premio_tipo, premio_id]
const LEVELS := [
	[1, "Primer brote", "Un Scriptbot se acerca por el carril central.", [2], 4, ["scriptbot"], "scriptbot", 1.0, 0.5, 150, 0, "plant", "girasolar"],
	[2, "Sol de mañana", "Más carriles, más robots. Los Girasolares te darán energía.", [1, 2, 3], 5, ["scriptbot"], "", 1.5, 0.6, 50, 0, "plant", "nuez_firewall"],
	[3, "Tokens y aliados", "Aparecen los Spambots. Gana tokens y llama a tu IA aliada.", ALL_LANES, 6, ["scriptbot", "spambot"], "spambot", 2.0, 0.7, 50, 1, "plant", "tokenizadora"],
	[4, "Muro de cartón", "Los Bots de Captcha traen escudos de cartón.", ALL_LANES, 7, Z1, "captchabot", 2.5, 0.8, 50, 2, "plant", "enredadera_captcha"],
	[5, "Asalto al jardín", "Todos los bots simples a la vez.", ALL_LANES, 8, Z1, "", 3.0, 0.9, 50, 2, "card", "boton_apagado"],
	[6, "Abrazos peligrosos", "El Abrazobot se forkea al morir.", ALL_LANES, 7, ["scriptbot", "spambot", "captchabot", "abrazobot"], "abrazobot", 3.0, 0.9, 50, 2, "plant", "mina_bug"],
	[7, "Emociones mixtas", "El Emojibot cambia de humor... y de velocidad de mordida.", ALL_LANES, 7, ["scriptbot", "captchabot", "abrazobot", "emojibot"], "emojibot", 3.5, 1.0, 50, 2, "plant_slot", ""],
	[8, "Fork infinito", "Muchos forks, poco tiempo.", ALL_LANES, 8, Z2, "", 4.0, 1.0, 50, 2, "plant", "cactus_antivirus"],
	[9, "Pull request hostil", "Revisa bien tus defensas antes de aceptar cambios.", ALL_LANES, 8, Z2, "", 4.5, 1.1, 50, 3, "card_slot", ""],
	[10, "Fusión de ramas", "Todo el repositorio contra tu jardín.", ALL_LANES, 9, Z2, "", 5.0, 1.2, 50, 3, "plant", "brotecito_solar"],
	[11, "Destilación", "Dragones que copian y Qilins en manada.", ALL_LANES, 8, ["scriptbot", "spambot", "dragon_destilado", "qilin_eficiente"], "dragon_destilado", 5.0, 1.2, 50, 3, "plant", "hongo_emp"],
	[12, "Pensamiento profundo", "El Razonador busca tu carril más débil.", ALL_LANES, 8, ["scriptbot", "captchabot", "dragon_destilado", "qilin_eficiente", "razonador_serie_o"], "razonador_serie_o", 5.5, 1.2, 50, 3, "card", "apagado_cadena"],
	[13, "Sin filtro", "Grokazo hace lo que quiere.", ALL_LANES, 8, ["scriptbot", "captchabot", "dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo"], "grokazo", 6.0, 1.3, 50, 3, "plant", "lanzasemillas_crio"],
	[14, "Doble personalidad", "Géminis se divide y se adapta a tu daño.", ALL_LANES, 8, ["captchabot", "emojibot", "dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo", "geminis_gemelo"], "geminis_gemelo", 6.5, 1.4, 50, 3, "plant_slot", ""],
	[15, "Garra autónoma", "OpenGarra arranca plantas y roba tokens.", ALL_LANES, 9, ["captchabot", "dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo", "geminis_gemelo", "opengarra"], "opengarra", 7.0, 1.5, 50, 4, "plant", "doble_commit"],
	[16, "Había una vez", "Claude Fable cuenta historias... con robots que no existen.", ALL_LANES, 8, ["scriptbot", "captchabot", "dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo", "claude_fable"], "claude_fable", 7.0, 1.5, 50, 4, "plant", "bambu_pararrayos"],
	[17, "Cerrojo total", "Mythos hackea tus mejores plantas.", ALL_LANES, 8, ["captchabot", "emojibot", "dragon_destilado", "grokazo", "geminis_gemelo", "mythos"], "mythos", 7.5, 1.6, 50, 4, "card", "red_team"],
	[18, "Estrella fugaz", "Astra se teletransporta y frena tus disparos.", ALL_LANES, 8, ["spambot", "qilin_eficiente", "razonador_serie_o", "opengarra", "claude_fable", "astra"], "astra", 8.0, 1.7, 50, 5, "plant", "nuez_firewall_pro"],
	[19, "Frontera", "La élite al completo.", ALL_LANES, 9, ["abrazobot", "emojibot", "razonador_serie_o", "grokazo", "geminis_gemelo", "opengarra", "claude_fable", "mythos", "astra"], "", 9.0, 1.8, 50, 5, "card", "alineamiento"],
	[20, "Antesala de la AGI", "Todo lo que la AGI ha creado viene a por ti.", ALL_LANES, 10, ["scriptbot", "spambot", "captchabot", "abrazobot", "emojibot", "dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo", "geminis_gemelo", "opengarra", "claude_fable", "mythos", "astra"], "", 10.0, 2.0, 50, 5, "plant", "girasolar_doble"],
]

const TUTORIALS := {
	1: [
		{"text": "¡Los robots IA quieren tu jardín! Haz clic en la carta Lanzasemillas (arriba).", "until": "select_plant"},
		{"text": "Ahora haz clic en una casilla del carril iluminado para plantarla.", "until": "place_plant"},
		{"text": "¡Bien! Haz clic en la Energía Solar que cae del cielo para recogerla.", "until": "collect_sun"},
		{"text": "Con 100 de energía planta otro Lanzasemillas. Si un robot llega a tu casa, la Podadora de emergencia lo frena (una vez por carril).", "until": "time:10"},
	],
	2: [
		{"text": "Planta Girasolares: generan energía extra cada 24 s. ¡Planta varios al principio!", "until": "place:girasolar"},
		{"text": "Más energía = más defensas. Recoge la energía que sueltan. Si te equivocas, usa la pala para quitar plantas.", "until": "time:10"},
	],
	3: [
		{"text": "Destruir robots suelta Tokens (moneda simbólica del juego). Tu IA aliada los usa para ayudarte.", "until": "tokens:3"},
		{"text": "¡Ya tienes 3 tokens! Toca la carta Autodestrucción y luego toca un robot.", "until": "card_used"},
		{"text": "¡Tu IA aliada te ayudó! Las cartas tienen recarga. Pausa con Esc y acelera con el botón x1/x2.", "until": "time:9"},
	],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/plants")
	DirAccess.make_dir_recursive_absolute("res://data/robots")
	DirAccess.make_dir_recursive_absolute("res://data/cards")
	DirAccess.make_dir_recursive_absolute("res://data/levels")
	for d in PLANTS:
		_save(_fill(PlantDataScript.new(), d), "res://data/plants/%s.tres" % d["id"])
	for d in ROBOTS:
		_save(_fill(RobotDataScript.new(), d), "res://data/robots/%s.tres" % d["id"])
	for d in CARDS:
		_save(_fill(CardDataScript.new(), d), "res://data/cards/%s.tres" % d["id"])
	for spec in LEVELS:
		_save(_make_level(spec), "res://data/levels/level_%02d.tres" % spec[0])
	_save(_make_boss_level(), "res://data/levels/level_21.tres")
	print("Contenido generado.")
	quit()


func _fill(res: Resource, d: Dictionary) -> Resource:
	for k in d.keys():
		res.set(k, d[k])
	return res


func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("No se pudo guardar %s (%d)" % [path, err])


func _make_level(spec: Array) -> Resource:
	var n: int = spec[0]
	var ld = LevelDataScript.new()
	ld.number = n
	ld.zone = int((n - 1) / 5) + 1
	ld.display_name = spec[1]
	ld.intro_text = spec[2]
	ld.active_lanes = PackedInt32Array(spec[3])
	ld.start_sun = spec[9]
	ld.start_tokens = spec[10]
	ld.unlock_type = spec[11]
	ld.unlock_id = spec[12]
	ld.first_wave_delay = 24.0 if n <= 2 else 18.0
	ld.skip_seed_select = n <= 3
	ld.tutorial_steps = TUTORIALS.get(n, [])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + n
	var wave_count: int = spec[4]
	var pool: Array = spec[5]
	var new_robot: String = spec[6]
	var base: float = spec[7]
	var inc: float = spec[8]
	var waves: Array[WaveData] = []
	for w in wave_count:
		var huge: bool = w == wave_count - 1 or (wave_count >= 7 and w == wave_count / 2 - 1)
		var budget := base + inc * w
		if huge:
			budget = budget * 2.0 + 1.0
		var wd = WaveDataScript.new()
		wd.is_huge = huge
		wd.duration = clampf(20.0 + budget * 1.3, 22.0, 38.0)
		var groups: Array = []
		if new_robot != "" and w <= 2 and w % 2 == 0:
			groups.append(_group(new_robot))
			budget -= COSTS[new_robot]
		var guard := 0
		while budget > 0.3 and guard < 60:
			guard += 1
			var id: String = _pick(pool, budget, rng, new_robot)
			groups.append(_group(id))
			budget -= COSTS[id]
		wd.groups = groups
		waves.append(wd)
	ld.waves = waves
	return ld


func _group(id: String) -> Dictionary:
	var g := {"robot": id, "count": 1, "interval": 1.0, "lane": -1}
	if GROUP_SIZE.has(id):
		g["count"] = GROUP_SIZE[id][0]
		g["interval"] = GROUP_SIZE[id][1]
	return g


func _pick(pool: Array, budget: float, rng: RandomNumberGenerator, favored: String) -> String:
	var affordable: Array = []
	for id in pool:
		if COSTS[id] <= budget + 0.5:
			affordable.append(id)
			if id == favored:
				affordable.append(id)
	if affordable.is_empty():
		var cheapest: String = pool[0]
		for id in pool:
			if COSTS[id] < COSTS[cheapest]:
				cheapest = id
		return cheapest
	return affordable[rng.randi() % affordable.size()]


func _make_boss_level() -> Resource:
	var ld = LevelDataScript.new()
	ld.number = 21
	ld.zone = 5
	ld.display_name = "La AGI"
	ld.intro_text = "La AGI ocupa tres carriles. Derrótala... o alinéala con 3 cartas de Alineamiento en su fase final."
	ld.active_lanes = PackedInt32Array(ALL_LANES)
	ld.start_sun = 400
	ld.start_tokens = 8
	ld.first_wave_delay = 20.0
	ld.is_boss = true
	var w1 = WaveDataScript.new()
	w1.duration = 25.0
	w1.groups = [_group("scriptbot"), _group("spambot"), _group("captchabot"), _group("scriptbot")]
	var w2 = WaveDataScript.new()
	w2.duration = 9999.0
	w2.is_huge = true
	w2.groups = [{"robot": "agi", "count": 1, "interval": 1.0, "lane": 2}]
	var waves: Array[WaveData] = [w1, w2]
	ld.waves = waves
	return ld
