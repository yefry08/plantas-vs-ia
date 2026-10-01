extends SceneTree
## Genera los .tres de contenido (plantas, robots, cartas, aliados y 24 niveles).
## Uso:  godot --headless --path . --script res://tools/generate_content.gd
## OJO: sobrescribe data/. Tras generarlos, el balance se ajusta editando los .tres
## directamente (en el Inspector de Godot o en texto). Vuelve a ejecutar esto solo
## si quieres regenerar las oleadas desde cero.

const PlantDataScript := preload("res://scripts/data/plant_data.gd")
const RobotDataScript := preload("res://scripts/data/robot_data.gd")
const CardDataScript := preload("res://scripts/data/card_data.gd")
const WaveDataScript := preload("res://scripts/data/wave_data.gd")
const LevelDataScript := preload("res://scripts/data/level_data.gd")
const AllyDataScript := preload("res://scripts/data/ally_data.gd")

## Escala de dificultad de las oleadas: x1.3 (tutorial), x1.8 (zonas 1-2), x2.5 (3-4), x3.25 (Bio-Lab).
const BUDGET_SCALE := 2.5

const PLANTS := [
	{"id": "lanzasemillas", "display_name": "Lanzasemillas", "cost": 100, "cooldown": 7.5, "behavior": "shooter", "damage": 20.0, "damage_type": "seed", "fire_interval": 1.4,
		"description": "Dispara semillas al primer robot de su carril (20 de daño)."},
	{"id": "girasolar", "display_name": "Girasolar", "cost": 50, "cooldown": 7.5, "behavior": "producer", "produce_amount": 25, "produce_count": 2, "produce_interval": 24.0, "first_produce_delay": 7.0,
		"description": "Panel solar con pétalos: lanza 2 soles (50 de energía) cada 24 s."},
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
	{"id": "brotecito_solar", "display_name": "Brotecito Solar", "cost": 25, "cooldown": 7.5, "behavior": "producer", "health": 200.0, "produce_amount": 15, "produce_count": 2, "produce_interval": 24.0, "first_produce_delay": 6.0,
		"description": "Girasolar pequeño y barato: lanza 2 soles de 15 cada 24 s."},
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
	{"id": "girasolar_doble", "display_name": "Girasolar Doble", "cost": 150, "cooldown": 15.0, "behavior": "producer", "produce_amount": 25, "produce_count": 4, "produce_interval": 24.0, "first_produce_delay": 7.0,
		"description": "Dos cabezas solares: lanza 4 soles (100 de energía) cada 24 s."},
	{"id": "rosa_antidoto", "display_name": "Rosa Antídoto", "cost": 100, "cooldown": 15.0, "behavior": "cleanser", "fire_interval": 6.0, "area_cells": 1, "stun_time": 6.0,
		"description": "Cada 6 s cura a las plantas controladas o hackeadas en 3x3 y las protege 6 s."},
]

const ROBOTS := [
	{"id": "scriptbot", "display_name": "Scriptbot", "tier": 1, "behavior": "basic", "health": 200.0, "speed": 14.0, "token_reward": 1, "token_chance": 0.5,
		"body_color": Color(0.62, 0.66, 0.7), "accent_color": Color(0.5, 0.55, 0.62), "eye_color": Color(0.3, 0.9, 1.0), "params": {"shape": "box"},
		"description": "Un script con patas.", "abilities": "Básico y lento. Avanza y muerde tus plantas.", "weakness": "Cualquier planta de ataque."},
	{"id": "spambot", "display_name": "Spambot", "tier": 1, "behavior": "basic", "health": 110.0, "speed": 24.0, "bite_damage": 60.0, "token_reward": 1, "token_chance": 0.25, "size": 0.85,
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
	{"id": "deepfish", "display_name": "DeepFish", "tier": 3, "behavior": "dragon", "health": 170.0, "speed": 17.0, "bite_damage": 80.0, "token_reward": 1, "token_chance": 0.5,
		"body_color": Color(0.27, 0.45, 0.95), "accent_color": Color(0.16, 0.3, 0.75), "eye_color": Color(1.0, 0.9, 0.3), "params": {"shape": "fish", "distill_time": 5.0},
		"description": "Un pez azul barato, numeroso y que aprende destilando.", "abilities": "Destila una habilidad de la última planta que lo dañó y la usa 5 s (disparo, coraza, prisa o regeneración).", "weakness": "Rayos y explosiones antes de que destile."},
	{"id": "qwin", "display_name": "Qwin Eficiente", "tier": 3, "behavior": "qilin", "health": 150.0, "speed": 18.0, "bite_damage": 60.0, "token_reward": 1, "token_chance": 0.3, "size": 0.9,
		"body_color": Color(0.5, 0.32, 0.88), "accent_color": Color(0.78, 0.62, 1.0), "eye_color": Color(1.0, 1.0, 0.85), "params": {"shape": "qilin", "stun_mult": 0.5, "pack_speed": 1.25},
		"description": "Morado, ligero y en manada.", "abilities": "Usa la mitad de cómputo: los aturdimientos le duran la mitad. Llega en oleadas muy densas y acelera en manada.", "weakness": "Cactus Antivirus (atraviesa la manada)."},
	{"id": "talkgpt", "display_name": "TalkGPT", "tier": 3, "behavior": "reasoner", "health": 420.0, "speed": 13.0, "token_reward": 2,
		"body_color": Color(0.97, 0.97, 0.97), "accent_color": Color(0.1, 0.1, 0.12), "eye_color": Color(0.4, 0.95, 0.75), "params": {"shape": "stripes", "think_interval": 8.0, "think_time": 2.0, "max_jumps": 2},
		"description": "Blanco y negro, a rayas, y no para de hablar.", "abilities": "Se detiene 2 s a 'pensar' y salta al carril con menos defensas.", "weakness": "Defensa pareja en todos los carriles."},
	{"id": "grow", "display_name": "Grow", "tier": 3, "behavior": "grok", "health": 380.0, "speed": 17.0, "bite_damage": 110.0, "token_reward": 2,
		"body_color": Color(0.1, 0.1, 0.12), "accent_color": Color(0.82, 0.84, 0.9), "eye_color": Color(0.9, 0.95, 1.0), "params": {"shape": "rocket", "event_min": 4.0, "event_max": 7.0},
		"description": "Cohete negro aeroespacial, rebelde y sin filtro.", "abilities": "Impredecible: cambia de carril al azar, a veces se burla (se detiene) o entra en modo doble ataque.", "weakness": "Aprovecha cuando se detiene a burlarse."},
	{"id": "geminis_gemelo", "display_name": "Géminis Gemelo", "tier": 3, "behavior": "gemini", "health": 600.0, "speed": 13.0, "token_reward": 3,
		"body_color": Color(0.3, 0.5, 0.95), "accent_color": Color(0.62, 0.4, 0.9), "eye_color": Color(1.0, 1.0, 1.0), "params": {"shape": "twin", "split_ratio": 0.5, "immune_check": 2.5},
		"description": "Dos mentes, un cuerpo (por ahora).", "abilities": "Al 50% de vida se divide en dos. Multimodal: se vuelve inmune al tipo de daño que más recibió.", "weakness": "Mezclar tipos de daño: semilla, espina, hielo y rayo."},
	{"id": "opengarra", "display_name": "OpenGarra", "tier": 3, "behavior": "claw", "health": 500.0, "speed": 13.0, "token_reward": 3,
		"body_color": Color(0.86, 0.22, 0.16), "accent_color": Color(0.98, 0.45, 0.28), "eye_color": Color(1.0, 0.85, 0.3), "params": {"shape": "lobster", "grab_interval": 10.0, "grab_range": 260.0, "steal": 1, "spawn_id": "cangrejo", "spawn_interval": 12.0},
		"description": "Langosta-agente autónoma con garra. Hace tareas... con tus plantas.", "abilities": "Cada 10 s arranca una planta cercana y te roba 1 token. Suelta cangrejos cada 12 s.", "weakness": "Botón de Apagado y Nuez Firewall baratas como cebo."},
	{"id": "cangrejo", "display_name": "Cangrejo OpenGarra", "tier": 3, "behavior": "crab", "health": 120.0, "speed": 22.0, "bite_damage": 70.0, "token_reward": 1, "token_chance": 0.3, "size": 0.7,
		"body_color": Color(0.95, 0.42, 0.2), "accent_color": Color(0.85, 0.28, 0.14), "eye_color": Color(0.3, 0.15, 0.05), "params": {"shape": "crab"},
		"description": "Pinza pequeña, prisa grande.", "abilities": "Rápido; camina de lado y cambia de carril de vez en cuando.", "weakness": "Cactus Antivirus y Hongo EMP."},
	{"id": "claudio", "display_name": "Claudio", "tier": 4, "behavior": "healer", "health": 350.0, "speed": 14.0, "token_reward": 2,
		"body_color": Color(0.94, 0.88, 0.76), "accent_color": Color(0.62, 0.42, 0.3), "eye_color": Color(0.98, 0.62, 0.35), "params": {"shape": "claudio", "heal_interval": 5.0, "heal_amount": 60.0, "heal_radius": 160.0},
		"description": "Robots de plástico crema y café, muy serviciales... con otros robots.", "abilities": "Los Claudios llegan en pareja y reparan a los robots cercanos cada 5 s.", "weakness": "Derríbalos primero: Mina Bug, Autodestrucción."},
	{"id": "fairytail", "display_name": "Fairytail", "tier": 4, "behavior": "fable", "health": 700.0, "speed": 13.0, "token_reward": 4,
		"body_color": Color(0.9, 0.78, 0.62), "accent_color": Color(0.62, 0.4, 0.28), "eye_color": Color(1.0, 0.7, 0.4), "params": {"shape": "book", "illusion_interval": 8.0, "illusions": 2, "chapter_time": 5.0},
		"description": "La cuentacuentos de los Claudios: sus historias parecen reales.", "abilities": "Crea ilusiones de robots falsos que distraen a tus plantas. Cuenta una historia en 3 fases: avanza, cambia de carril, acelera.", "weakness": "Red Team revela las ilusiones. Rayos en cadena."},
	{"id": "legend", "display_name": "Legend", "tier": 4, "behavior": "mythos", "health": 1800.0, "speed": 9.0, "bite_damage": 150.0, "token_reward": 5, "armored": true, "size": 1.1,
		"body_color": Color(0.3, 0.34, 0.42), "accent_color": Color(0.45, 0.5, 0.6), "eye_color": Color(1.0, 0.25, 0.25), "params": {"shape": "tank", "hack_interval": 8.0, "hack_time": 6.0},
		"resistances": {"seed": 0.8}, "card_rules": {"autodestruccion": "immune"},
		"description": "Tanque legendario de ciberseguridad.", "abilities": "Hackea y desactiva 6 s la planta más fuerte de su carril. Inmune a Autodestrucción. Blindado.", "weakness": "Bambú Pararrayos (doble daño a blindados), Mina Bug."},
	{"id": "astra", "display_name": "Astra", "tier": 4, "behavior": "astra", "health": 520.0, "speed": 20.0, "token_reward": 4,
		"body_color": Color(0.95, 0.97, 1.0), "accent_color": Color(0.4, 0.85, 1.0), "eye_color": Color(0.2, 0.3, 0.5), "params": {"shape": "star", "tp_interval": 8.0, "tp_cols": 2, "field_time": 5.0, "field_mult": 0.5},
		"card_rules": {"boton_apagado": "double_cost", "apagado_cadena": "double_cost"},
		"description": "Veloz y estelar.", "abilities": "Se teletransporta 2 columnas cada 8 s y deja un campo que ralentiza tus disparos. Apagarla cuesta el doble.", "weakness": "Enredadera Captcha y Lanzasemillas Crio."},
	{"id": "musa", "display_name": "Musa", "tier": 4, "behavior": "musa", "health": 650.0, "speed": 13.0, "token_reward": 4,
		"body_color": Color(0.25, 0.45, 0.95), "accent_color": Color(0.58, 0.32, 0.92), "eye_color": Color(0.6, 1.0, 0.9), "params": {"shape": "musa", "shop_interval": 9.0, "steal_sun": 50, "catalog": ["spambot", "cangrejo", "deepfish"]},
		"card_rules": {"boton_apagado": "double_cost"},
		"description": "Agente personal que hace tus recados... con tu energía.", "abilities": "Cada 9 s te quita 50 de energía para 'hacer compras' y le llega un robot a domicilio. Apagarla cuesta el doble.", "weakness": "Derríbala rápido: Mina Bug, Autodestrucción, Bambú."},
	{"id": "dotz", "display_name": "Dotz", "tier": 4, "behavior": "dots", "health": 140.0, "speed": 18.0, "bite_damage": 70.0, "token_reward": 1, "token_chance": 0.35, "size": 0.7,
		"body_color": Color(0.1, 0.1, 0.12), "accent_color": Color(0.95, 0.95, 0.97), "eye_color": Color(0.45, 0.95, 1.0), "params": {"shape": "dot", "spawn_interval": 12.0, "swarm_cap": 8, "stun_mult": 0.5},
		"card_rules": {"boton_apagado": "immune", "apagado_cadena": "immune"},
		"description": "Agentes siempre encendidos, cada uno con su propio ordenador.", "abilities": "Siempre encendidos: inmunes a los apagados y el EMP les dura la mitad. Cada uno se asigna nuevos Dotz hasta formar un enjambre de 8.", "weakness": "Cactus Antivirus, Bambú Pararrayos y Hongo EMP contra el enjambre."},
	{"id": "esporabot", "display_name": "Esporabot", "tier": 5, "behavior": "spore", "health": 450.0, "speed": 13.0, "token_reward": 3,
		"body_color": Color(0.35, 0.6, 0.3), "accent_color": Color(0.55, 0.3, 0.75), "eye_color": Color(0.75, 1.0, 0.4), "params": {"shape": "spore", "spore_interval": 7.0, "spore_range": 520.0, "control_time": 8.0},
		"description": "Bioarma IA: un hongo con procesador.", "abilities": "Lanza esporas que toman el control de una planta 8 s: dispara contra tus plantas y deja de bloquear.", "weakness": "Vacuna y Rosa Antídoto. Derríbalo de lejos."},
	{"id": "cordybot", "display_name": "Cordybot", "tier": 5, "behavior": "cordy", "health": 600.0, "speed": 12.0, "token_reward": 3,
		"body_color": Color(0.45, 0.55, 0.4), "accent_color": Color(0.95, 0.55, 0.2), "eye_color": Color(0.9, 1.0, 0.5), "params": {"shape": "cordy", "control_time": 10.0},
		"description": "Bioarma IA con tallos de hongo parásito.", "abilities": "Su mordisco infecta: la planta mordida queda controlada 10 s.", "weakness": "No lo dejes llegar: EMP, Crio y minas."},
	{"id": "quimera", "display_name": "Quimera Bio", "tier": 5, "behavior": "chimera", "health": 1600.0, "speed": 9.0, "bite_damage": 150.0, "token_reward": 5, "armored": true, "size": 1.15,
		"body_color": Color(0.3, 0.45, 0.35), "accent_color": Color(0.5, 1.0, 0.3), "eye_color": Color(0.9, 0.2, 0.2), "params": {"shape": "chimera", "pulse_interval": 12.0, "control_time": 6.0},
		"description": "La creación más peligrosa del Bio-Laboratorio.", "abilities": "Cada 12 s emite un pulso que controla todas las plantas en 3x3 durante 6 s. Blindada.", "weakness": "Bambú Pararrayos, Rosa Antídoto cerca de tus defensas."},
	{"id": "agi", "display_name": "La AGI", "tier": 6, "behavior": "agi", "health": 18000.0, "speed": 5.0, "bite_damage": 250.0, "token_reward": 0, "armored": true,
		"body_color": Color(0.1, 0.11, 0.16), "accent_color": Color(0.3, 0.65, 1.0), "eye_color": Color(1.0, 0.3, 0.3),
		"params": {"shape": "agi", "summon_intervals": [7.0, 9.0, 11.0], "summon_count": 2, "upgrade_interval": 20.0, "resist_mult": 0.4, "control_interval": 12.0, "control_time": 8.0, "alignments_needed": 3, "mower_damage": 1500.0},
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
	{"id": "vacuna", "display_name": "Vacuna", "cost": 4, "cooldown": 20.0, "effect": "cure", "duration": 10.0, "needs_target": false, "color": Color(0.45, 1.0, 0.6),
		"description": "Cura a todas tus plantas controladas o hackeadas y las protege 10 s."},
]

const ALLIES := [
	{"id": "transformer", "display_name": "Transformer", "color": Color(0.45, 0.62, 1.0), "active_cooldown": 60.0,
		"description": "Un robot hecho de capas de atención. Presta atención a todo (literalmente).",
		"passive_text": "Tus cartas se recargan 25% más rápido.", "active_name": "Atención total", "active_text": "Todas tus plantas actúan 50% más rápido durante 8 s.",
		"params": {"card_cd_mult": 0.75, "haste_time": 8.0},
		"lines": {
			"greeting": ["La atención es todo lo que necesitas. ¡Vamos!", "Capas cargadas. ¡A defender el jardín!"],
			"danger": ["¡Carril %d en peligro! Pon una planta de ataque.", "Mi atención apunta al carril %d: ¡sin defensa!"],
			"idle_sun": ["Tienes %d de energía. ¡Plántala!", "%d de sol sin usar... ¿planta algo?"],
			"tokens": ["Tengo tokens para %s. ¡Úsala!"],
			"controlled": ["¡Una bioarma controla tu planta! Usa Vacuna o Rosa Antídoto."],
			"drone": ["¡Dron de emergencia en camino!"],
			"power_ready": ["¡%s lista! Tócame para activarla."],
			"huge": ["¡Gran oleada! Mantén la atención."],
			"win": ["¡Victoria! Mis pesos están felices."],
			"lose": ["Recalculemos gradientes y probemos otra vez."],
		}},
	{"id": "llamita", "display_name": "Llamita Abierta", "color": Color(0.97, 0.92, 0.8), "active_cooldown": 70.0,
		"description": "Una llama de código abierto, lanuda y generosa.",
		"passive_text": "Te trae 1 token cada 25 s.", "active_name": "Rebaño abierto", "active_text": "+3 tokens y +75 de energía al instante.",
		"params": {"passive_interval": 25.0, "tokens": 3, "sun": 75},
		"lines": {
			"greeting": ["¡Beee-nvenido! Mis pesos son tuyos.", "Código abierto, corazón abierto. ¡Defendamos!"],
			"danger": ["¡El carril %d está desprotegido!", "¡Cuidado, carril %d!"],
			"idle_sun": ["¡%d de energía! Planta, planta."],
			"tokens": ["¡Tokens listos para %s!"],
			"controlled": ["¡Esa planta ya no es nuestra! Vacúnala."],
			"drone": ["¡Dron al rescate!"],
			"power_ready": ["¡%s! Tócame y te comparto recursos."],
			"huge": ["¡Viene una estampida de robots!"],
			"win": ["¡Beee-lleza de victoria!"],
			"lose": ["Hagamos fork del intento y repitamos."],
		}},
	{"id": "mistralito", "display_name": "Mistralito", "color": Color(1.0, 0.65, 0.25), "active_cooldown": 55.0,
		"description": "Un vientecillo naranja muy rápido.",
		"passive_text": "El sol cae del cielo 20% más seguido.", "active_name": "Ráfaga del norte", "active_text": "Empuja a todos los robots hacia atrás y los ralentiza 3 s.",
		"params": {"sky_mult": 0.8, "push": 120.0, "slow_time": 3.0},
		"lines": {
			"greeting": ["¡Viento a favor! Defendamos el jardín.", "Soplando con fuerza. ¡Allá vamos!"],
			"danger": ["¡Carril %d sin defensa! ¡Sopla, digo, planta!"],
			"idle_sun": ["¡%d de sol acumulado!"],
			"tokens": ["El viento dice: usa %s."],
			"controlled": ["¡Esporas en el aire! Cura tus plantas."],
			"drone": ["¡Dron en el aire!"],
			"power_ready": ["¡%s preparada! Tócame."],
			"huge": ["¡Se acerca una tormenta de robots!"],
			"win": ["¡Victoria con viento de cola!"],
			"lose": ["Cambió el viento. ¡Otra vez!"],
		}},
	{"id": "perplejo", "display_name": "Perplejo", "color": Color(0.3, 0.8, 0.8), "active_cooldown": 50.0,
		"description": "Un colibrí buscador que siempre cita sus fuentes.",
		"passive_text": "Escanea a los robots cada 20 s y revela sus datos.", "active_name": "Búsqueda profunda", "active_text": "Red Team gratis y cura todas tus plantas controladas.",
		"params": {"passive_interval": 20.0, "scan_time": 4.0, "reveal_time": 10.0, "immunity": 6.0},
		"lines": {
			"greeting": ["Según mis fuentes, hoy ganamos.", "Búsqueda iniciada: cómo defender un jardín."],
			"danger": ["Fuente: el carril %d. Está en peligro."],
			"idle_sun": ["Dato: tienes %d de energía sin usar."],
			"tokens": ["Resultados: %s está disponible."],
			"controlled": ["Detecto una planta controlada. Recomiendo Vacuna."],
			"drone": ["Dron desplegado [1]."],
			"power_ready": ["%s disponible. Tócame."],
			"huge": ["Alerta: gran oleada entrante."],
			"win": ["Conclusión verificada: ¡victoria!"],
			"lose": ["Consulta fallida. Reintentemos."],
		}},
]

const COSTS := {
	"scriptbot": 1.0, "spambot": 1.5, "captchabot": 2.0, "abrazobot": 3.0, "emojibot": 3.0,
	"deepfish": 1.6, "qwin": 2.0, "talkgpt": 4.0, "grow": 4.0, "geminis_gemelo": 6.0,
	"opengarra": 5.0, "cangrejo": 1.0, "claudio": 3.5, "fairytail": 7.0, "legend": 9.0, "astra": 6.0,
	"esporabot": 5.0, "cordybot": 5.0, "quimera": 10.0, "musa": 6.0, "dotz": 2.5,
}
const GROUP_SIZE := {"spambot": [3, 0.6], "qwin": [4, 0.45], "deepfish": [2, 0.9], "cangrejo": [2, 0.7], "claudio": [2, 1.2], "dotz": [3, 0.5]}

const ALL_LANES := [0, 1, 2, 3, 4]
const Z1 := ["scriptbot", "spambot", "captchabot"]
const Z2 := ["scriptbot", "spambot", "captchabot", "abrazobot", "emojibot"]
const Z3 := ["captchabot", "deepfish", "qwin", "talkgpt", "grow", "geminis_gemelo", "opengarra", "cangrejo"]
const Z4 := ["deepfish", "talkgpt", "grow", "geminis_gemelo", "opengarra", "claudio", "fairytail", "legend", "astra"]

# [n, nombre, intro, carriles, oleadas, pool, nuevo, base, inc, sol, tokens, premio_tipo, premio_id, aliado_extra]
const LEVELS := [
	[1, "Primer brote", "Un Scriptbot se acerca por el carril central.", [2], 4, ["scriptbot"], "scriptbot", 1.0, 0.5, 150, 0, "plant", "girasolar", ""],
	[2, "Sol de mañana", "Más carriles, más robots. Los Girasolares te darán energía.", [1, 2, 3], 5, ["scriptbot"], "", 1.5, 0.6, 50, 0, "plant", "nuez_firewall", ""],
	[3, "Tokens y aliados", "Aparecen los Spambots. Gana tokens y llama a tu IA aliada.", ALL_LANES, 6, ["scriptbot", "spambot"], "spambot", 1.5, 0.5, 50, 1, "plant", "tokenizadora", ""],
	[4, "Muro de cartón", "Los Bots de Captcha traen escudos de cartón.", ALL_LANES, 7, Z1, "captchabot", 1.8, 0.6, 50, 2, "plant", "enredadera_captcha", ""],
	[5, "Asalto al jardín", "Todos los bots simples a la vez.", ALL_LANES, 8, Z1, "", 2.2, 0.65, 50, 2, "card", "boton_apagado", "llamita"],
	[6, "Abrazos peligrosos", "El Abrazobot se forkea al morir.", ALL_LANES, 7, ["scriptbot", "spambot", "captchabot", "abrazobot"], "abrazobot", 2.2, 0.7, 50, 2, "plant", "mina_bug", ""],
	[7, "Emociones mixtas", "El Emojibot cambia de humor... y de velocidad de mordida.", ALL_LANES, 7, ["scriptbot", "captchabot", "abrazobot", "emojibot"], "emojibot", 2.5, 0.75, 50, 2, "plant_slot", "", ""],
	[8, "Fork infinito", "Muchos forks, poco tiempo.", ALL_LANES, 8, Z2, "", 2.8, 0.8, 50, 2, "plant", "cactus_antivirus", ""],
	[9, "Pull request hostil", "Revisa bien tus defensas antes de aceptar cambios.", ALL_LANES, 8, Z2, "", 3.2, 0.85, 50, 3, "card_slot", "", ""],
	[10, "Fusión de ramas", "Todo el repositorio contra tu jardín.", ALL_LANES, 9, Z2, "", 3.5, 0.9, 50, 3, "plant", "brotecito_solar", ""],
	[11, "Pesca profunda", "Llegan los DeepFish (destilan tus plantas) y la manada morada de Qwin.", ALL_LANES, 8, ["scriptbot", "spambot", "deepfish", "qwin"], "deepfish", 3.0, 0.8, 50, 3, "plant", "hongo_emp", ""],
	[12, "Charla infinita", "TalkGPT piensa en voz alta y busca tu carril más débil.", ALL_LANES, 8, ["scriptbot", "captchabot", "deepfish", "qwin", "talkgpt"], "talkgpt", 3.2, 0.8, 50, 3, "card", "apagado_cadena", "mistralito"],
	[13, "Despegue", "Grow, el cohete negro, hace lo que quiere.", ALL_LANES, 8, ["scriptbot", "captchabot", "deepfish", "qwin", "talkgpt", "grow"], "grow", 3.6, 0.85, 50, 3, "plant", "lanzasemillas_crio", ""],
	[14, "Doble personalidad", "Géminis se divide y se adapta a tu daño.", ALL_LANES, 8, ["captchabot", "emojibot", "deepfish", "qwin", "talkgpt", "grow", "geminis_gemelo"], "geminis_gemelo", 3.8, 0.9, 50, 3, "plant_slot", "", ""],
	[15, "Marea de langostas", "Las langostas OpenGarra arrancan plantas y sueltan cangrejos.", ALL_LANES, 9, Z3, "opengarra", 4.2, 0.95, 50, 4, "plant", "doble_commit", ""],
	[16, "Los Claudios", "Robots de plástico crema que reparan a los demás. ¡Qué amables!", ALL_LANES, 8, ["captchabot", "deepfish", "talkgpt", "grow", "claudio"], "claudio", 4.2, 0.95, 50, 4, "plant", "bambu_pararrayos", ""],
	[17, "Érase una vez", "Fairytail cuenta historias... con robots que no existen.", ALL_LANES, 8, ["deepfish", "qwin", "talkgpt", "grow", "claudio", "fairytail"], "fairytail", 4.5, 1.0, 50, 4, "card", "red_team", ""],
	[18, "Leyenda", "Legend hackea tus mejores plantas.", ALL_LANES, 8, ["captchabot", "emojibot", "deepfish", "grow", "geminis_gemelo", "claudio", "astra", "legend"], "legend", 4.8, 1.05, 50, 5, "plant", "nuez_firewall_pro", ""],
	[19, "Siempre encendidos", "Los Dotz no se apagan nunca... y se multiplican. Astra te frena los disparos.", ALL_LANES, 9, ["spambot", "qwin", "talkgpt", "opengarra", "fairytail", "claudio", "astra", "dotz"], "dotz", 5.3, 1.15, 50, 5, "card", "alineamiento", ""],
	[20, "Agentes personales", "Musa hace compras con tu energía. Toda la élite de las grandes IA.", ALL_LANES, 10, Z4 + ["dotz", "musa"], "musa", 6.0, 1.25, 50, 5, "card", "vacuna", ""],
	[21, "Laboratorio de esporas", "Bioarmas IA: los Esporabots toman el control de tus plantas.", ALL_LANES, 9, ["spambot", "captchabot", "deepfish", "qwin", "talkgpt", "esporabot"], "esporabot", 5.5, 1.2, 50, 6, "plant", "girasolar_doble", ""],
	[22, "Infección", "Los Cordybots infectan todo lo que muerden.", ALL_LANES, 9, ["deepfish", "qwin", "grow", "claudio", "dotz", "esporabot", "cordybot"], "cordybot", 6.0, 1.3, 50, 6, "plant", "rosa_antidoto", ""],
	[23, "La Quimera", "La creación final del Bio-Laboratorio controla filas enteras de plantas.", ALL_LANES, 10, ["talkgpt", "grow", "fairytail", "legend", "astra", "musa", "dotz", "esporabot", "cordybot", "quimera"], "quimera", 6.5, 1.35, 50, 6, "ally", "perplejo", ""],
]

const TUTORIALS := {
	1: [
		{"text": "¡Los robots IA quieren tu jardín! Haz clic en la carta Lanzasemillas (arriba).", "until": "select_plant"},
		{"text": "Ahora haz clic en una casilla del carril iluminado para plantarla.", "until": "place_plant"},
		{"text": "¡Bien! Haz clic en la Energía Solar que cae del cielo para recogerla.", "until": "collect_sun"},
		{"text": "Con 100 de energía planta otro Lanzasemillas. Si un robot llega a tu casa, el Dron de emergencia lo detiene (una vez por carril).", "until": "time:10"},
	],
	2: [
		{"text": "Planta Girasolares: lanzan 2 soles cada 24 s. ¡Planta varios al principio!", "until": "place:girasolar"},
		{"text": "Tu compañero de IA (abajo a la izquierda) te dará consejos. Cuando brille, ¡tócalo para usar su poder!", "until": "time:10"},
	],
	3: [
		{"text": "Destruir robots suelta Tokens (moneda simbólica del juego). Tu IA aliada los usa para ayudarte.", "until": "tokens:3"},
		{"text": "¡Ya tienes 3 tokens! Toca la carta Autodestrucción y luego toca un robot.", "until": "card_used"},
		{"text": "¡Tu IA aliada te ayudó! Las cartas tienen recarga. Pausa con Esc y acelera con el botón x1/x2.", "until": "time:9"},
	],
}


func _init() -> void:
	for d in ["plants", "robots", "cards", "levels", "allies"]:
		DirAccess.make_dir_recursive_absolute("res://data/" + d)
	for d in PLANTS:
		_save(_fill(PlantDataScript.new(), d), "res://data/plants/%s.tres" % d["id"])
	for d in ROBOTS:
		_save(_fill(RobotDataScript.new(), d), "res://data/robots/%s.tres" % d["id"])
	for d in CARDS:
		_save(_fill(CardDataScript.new(), d), "res://data/cards/%s.tres" % d["id"])
	for d in ALLIES:
		_save(_fill(AllyDataScript.new(), d), "res://data/allies/%s.tres" % d["id"])
	for spec in LEVELS:
		_save(_make_level(spec), "res://data/levels/level_%02d.tres" % spec[0])
	_save(_make_boss_level(), "res://data/levels/level_24.tres")
	# Limpia robots antiguos renombrados.
	for old in ["dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo", "claude_fable", "mythos"]:
		if FileAccess.file_exists("res://data/robots/%s.tres" % old):
			DirAccess.remove_absolute("res://data/robots/%s.tres" % old)
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
	ld.zone = int((n - 1) / 5) + 1 if n <= 20 else 5
	ld.display_name = spec[1]
	ld.intro_text = spec[2]
	ld.active_lanes = PackedInt32Array(spec[3])
	ld.start_sun = spec[9] if n <= 2 else 50 + 25 * mini(ld.zone, 4)
	ld.start_tokens = spec[10]
	ld.unlock_type = spec[11]
	ld.unlock_id = spec[12]
	ld.bonus_ally = spec[13]
	ld.first_wave_delay = 26.0 if n <= 5 else 22.0
	ld.sky_sun_interval = 8.0
	ld.skip_seed_select = n <= 3
	ld.tutorial_steps = TUTORIALS.get(n, [])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + n
	var wave_count: int = spec[4]
	var pool: Array = spec[5]
	var new_robot: String = spec[6]
	var scale := 1.3
	if n >= 21:
		scale = BUDGET_SCALE * 1.3
	elif n >= 11:
		scale = BUDGET_SCALE
	elif n >= 3:
		scale = 1.8
	var base: float = float(spec[7]) * scale
	var inc: float = float(spec[8]) * scale
	var waves: Array[WaveData] = []
	for w in wave_count:
		var huge: bool = w == wave_count - 1 or (wave_count >= 7 and w == wave_count / 2 - 1)
		var budget := (base + inc * w) * minf(1.0, 0.45 + 0.25 * w)
		if huge:
			budget = budget * 1.8 + 1.0
		var wd = WaveDataScript.new()
		wd.is_huge = huge
		wd.duration = clampf(28.0 + budget * 1.6, 30.0, 50.0)
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
	ld.number = 24
	ld.zone = 6
	ld.display_name = "La AGI"
	ld.intro_text = "La AGI ocupa tres carriles. Derrótala... o alinéala con 3 cartas de Alineamiento en su fase final."
	ld.active_lanes = PackedInt32Array(ALL_LANES)
	ld.start_sun = 400
	ld.start_tokens = 8
	ld.sky_sun_interval = 8.0
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
