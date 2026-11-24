extends RefCounted
# Datos del juego Litopulso V8.0 (traducidos del prototipo web). Solo lectura.

const CFG := {"hp": 100, "energy": 5, "maxEnergy": 10, "regen": 2, "bonus": 1, "maxTurns": 30, "scMax": 5, "overDmg": 60, "handSize": 5, "passiveSlots": 2}
const TYPE_NAME := {"attack": "Ataque", "guard": "Defensa", "dodge": "Desvío", "skill": "Habilidad", "over": "Sobrecarga"}
const OVER := {"id": "over", "name": "Sobrecarga", "type": "over", "cost": 0, "dmg": 60}
const BASE_TYPES := ["attack", "guard", "dodge", "skill"]
const PERSONAS := [
	{"attack": 4, "skill": 3, "guard": 1, "dodge": 1},
	{"attack": 1, "skill": 2, "guard": 3, "dodge": 3},
	{"attack": 2, "skill": 2, "guard": 2, "dodge": 2}
]
const EV_LATE := ["colapso", "desgaste", "furia", "pesado"]
const EV_AT := [10, 15, 20, 25]
const ARENAS := [
	{"n": "Llanura de cuarzo", "r": "Sin regla especial."},
	{"n": "Cantera hueca", "r": "Todos los golpes hacen +3 de daño."},
	{"n": "Reactor frío", "r": "Los dos recuperan +1 de energía por turno."},
	{"n": "Geoda eléctrica", "r": "La Sobrecarga se activa con racha 4."},
	{"n": "Grieta del Hexx", "r": "Los eventos salen cada 5 turnos (5, 10, 15, 20, 25)."}
]
const CHAPS := [
	{"n": "La grieta del Hexx", "b": "El guardián de la grieta"},
	{"n": "La cantera olvidada", "b": "El Coloso de roca"},
	{"n": "Pulseras vacías", "b": "La Custodia fría"},
	{"n": "El reactor dormido", "b": "El Núcleo furioso"},
	{"n": "El corazón del Hexx", "b": "El Origen"}
]

const CARDS := {
	"atk":      { "id": "atk",      "name": "Martillo",  "type": "attack", "r": "g", "cost": 3, "dmg": 20, "text": "Quita 20 de vida." },
	"fast":     { "id": "fast",     "name": "Pulso",     "type": "attack", "r": "b", "cost": 2, "dmg": 15, "text": "Ataque barato: quita 15 de vida." },
	"heavy":    { "id": "heavy",    "name": "Derrumbe",  "type": "attack", "r": "r", "cost": 4, "dmg": 27, "text": "Ataque caro: quita 27 de vida." },
	"impeto":   { "id": "impeto",   "name": "Ímpetu",    "type": "attack", "r": "b", "cost": 3, "dmg": 16, "gain": 1, "text": "Quita 16 de vida y, si golpea, recuperas 1 de energía." },
	"alud":     { "id": "alud",     "name": "Alud",      "type": "attack", "r": "b", "cost": 4, "dmg": 30, "missLoss": 2, "text": "Quita 30 de vida, pero si el rival usa Defensa pierdes 2 de energía más." },
	"guard":    { "id": "guard",    "name": "Muro",      "type": "guard",  "r": "g", "cost": 1, "text": "Frena el Ataque." },
	"counter":  { "id": "counter",  "name": "Rebote",    "type": "guard",  "r": "b", "cost": 2, "reflect": 8, "text": "Frena el Ataque y le devuelve 8 de daño." },
	"barrera":  { "id": "barrera",  "name": "Barrera",   "type": "guard",  "r": "g", "cost": 2, "gain": 2, "text": "Frena el Ataque y, si lo logra, recuperas 2 de energía." },
	"fortaleza":{ "id": "fortaleza","name": "Fortaleza", "type": "guard",  "r": "r", "cost": 2, "blockAll": true, "text": "Frena el Ataque y también la Sobrecarga completa (otras Defensas frenan solo la mitad). La Habilidad la rompe." },
	"dodge":    { "id": "dodge",    "name": "Giro",      "type": "dodge",  "r": "g", "cost": 1, "text": "Evita la Habilidad." },
	"feint":    { "id": "feint",    "name": "Sombra",    "type": "dodge",  "r": "b", "cost": 2, "half": true, "text": "Evita la Habilidad y recibe solo la mitad del daño de un Ataque." },
	"cauce":    { "id": "cauce",    "name": "Cauce",     "type": "dodge",  "r": "g", "cost": 2, "gain": 3, "text": "Evita la Habilidad y, si lo logra, recuperas 3 de energía." },
	"espejismo":{ "id": "espejismo","name": "Espejismo", "type": "dodge",  "r": "b", "cost": 2, "drain": 3, "text": "Evita la Habilidad y, si lo logra, el rival pierde 3 de energía." },
	"skill":    { "id": "skill",    "name": "Fractura",  "type": "skill",  "r": "g", "cost": 6, "dmg": 35, "text": "Quita 35 de vida. Rompe la Defensa." },
	"light":    { "id": "light",    "name": "Grieta",    "type": "skill",  "r": "b", "cost": 4, "dmg": 23, "text": "Habilidad barata: quita 23 de vida." },
	"crush":    { "id": "crush",    "name": "Implosión", "type": "skill",  "r": "r", "cost": 8, "dmg": 44, "text": "Habilidad enorme: quita 44 de vida." },
	"iman":     { "id": "iman",     "name": "Imán",      "type": "skill",  "r": "b", "cost": 4, "dmg": 15, "drain": 2, "text": "Quita 15 de vida y, si golpea, el rival pierde 2 de energía." },
	"grito":    { "id": "grito",    "name": "Grito",     "type": "skill",  "r": "r", "cost": 4, "dmg": 17, "lockDodge": true, "text": "Quita 17 de vida y, si golpea, el rival no puede usar Desvío el siguiente turno." }
}

const PASSIVES := {
	"core":     { "robot": "petreo",  "name": "Núcleo eficiente", "short": "Núcleo",   "idle": 1,  "text": "Recuperas 1 de energía extra en los turnos en que nadie recibe daño." },
	"reflex":   { "robot": "petreo",  "name": "Reflejos",         "short": "Reflejos", "def": 4,   "text": "Si tu Defensa o Desvío aciertan, recuperas 4 de energía extra en vez de 1." },
	"stone":    { "robot": "petreo",  "name": "Piel de piedra",   "short": "Piel",     "hp": 20,   "text": "Empiezas con 20 de vida extra." },
	"fury":     { "robot": "petreo",  "name": "Furia",            "short": "Furia",    "fury": 6, "text": "Tus golpes hacen +6 de daño mientras tengas menos vida que el rival." },
	"g_roca":   { "robot": "granito", "name": "Roca madre",       "short": "Roca",     "hp": 20,   "text": "Empiezas con 20 de vida extra." },
	"g_carga":  { "robot": "granito", "name": "Carga lenta",      "short": "Carga",    "start": 2, "text": "Empiezas con 2 de energía extra." },
	"g_coraza": { "robot": "granito", "name": "Coraza",           "short": "Coraza",   "def": 4,   "text": "Si tu Defensa o Desvío aciertan, recuperas 4 de energía extra en vez de 1." },
	"g_terco":  { "robot": "granito", "name": "Terquedad",        "short": "Terco",    "fury": 7, "text": "Tus golpes hacen +7 de daño mientras tengas menos vida que el rival." },
	"c_reson":  { "robot": "cuarzo",  "name": "Resonancia",       "short": "Resonancia", "idle": 2, "text": "Recuperas 2 de energía extra en los turnos en que nadie recibe daño." },
	"c_filo":   { "robot": "cuarzo",  "name": "Filo de cristal",  "short": "Filo",     "edge": 4, "text": "Todos tus golpes hacen +4 de daño." },
	"c_templa": { "robot": "cuarzo",  "name": "Cristal templado", "short": "Templado", "hp": 16,   "text": "Empiezas con 16 de vida extra." },
	"c_destello":{ "robot": "cuarzo", "name": "Destello",         "short": "Destello", "start": 2, "edge": 2, "text": "Empiezas con 2 de energía extra y tus golpes hacen +2 de daño." }
}

const MODS := {
	"m_nuc":   { "part": "head", "r": "r", "name": "Núcleo comprimido", "costHp": 15, "pro": "Tu racha sube al máximo: Sobrecarga lista.", "con": "Pierdes 15 de vida." },
	"m_visor": { "part": "head", "r": "b", "name": "Visor afilado",     "costEn": 2,  "pro": "Ves la carta que jugará el rival este turno.", "con": "Cuesta 2 de energía." },
	"m_antena":{ "part": "head", "r": "b", "name": "Antena",            "costHp": 12, "pro": "El rival pierde 4 de energía.", "con": "Pierdes 12 de vida." },
	"m_blind": { "part": "body", "r": "b", "name": "Blindaje",          "costEn": 2,  "pro": "Este turno recibes la mitad del daño.", "con": "Cuesta 2 de energía." },
	"m_reac":  { "part": "body", "r": "r", "name": "Reactor inestable", "costHp": 20, "pro": "Ganas 5 de energía ahora.", "con": "Pierdes 20 de vida." },
	"m_banco": { "part": "body", "r": "b", "name": "Banco amplio",      "costEn": 1,  "pro": "Cambias 3 de tus cartas por otras al azar.", "con": "Cuesta 1 de energía. No sirve durante Barajar ni Mano corta." },
	"m_imp":   { "part": "legs", "r": "b", "name": "Impulso",           "costHp": 10, "pro": "Ganas 3 de racha ahora.", "con": "Pierdes 10 de vida." },
	"m_anc":   { "part": "legs", "r": "b", "name": "Anclaje",           "costEn": 3,  "pro": "Este turno no recibes daño.", "con": "Cuesta 3 de energía." },
	"m_salto": { "part": "legs", "r": "r", "name": "Salto",             "costEn": 3,  "pro": "Este turno tus golpes hacen +25 de daño.", "con": "Cuesta 3 de energía." },
	"s_petreo":{ "part": "spec", "r": "r", "robot": "petreo",  "name": "Piel viva",    "costEn": 4,  "pro": "Recuperas 20 % de tu vida máxima.", "con": "Cuesta 4 de energía." },
	"s_granito":{ "part": "spec", "r": "r", "robot": "granito", "name": "Núcleo lento", "costHp": 25, "pro": "30 de daño directo al rival (nunca lo deja en menos de 1).", "con": "Pierdes 25 de vida." },
	"s_cuarzo":{ "part": "spec", "r": "r", "robot": "cuarzo",  "name": "Prisma",       "costHp": 10, "pro": "Robas 3 de energía al rival.", "con": "Pierdes 10 de vida." }
}

const ROBOTS := {
	"petreo":  { "name": "Pétreo",  "hp": 169, "en": 5, "color": "#3fd9d2", "short": "Equilibrado", "text": "169 de vida y 5 de energía inicial." },
	"granito": { "name": "Granito", "hp": 190, "en": 3, "color": "#ff9a2e", "short": "Resistente",  "text": "190 de vida, pero empieza con solo 3 de energía." },
	"cuarzo":  { "name": "Cuarzo",  "hp": 142, "en": 8, "color": "#a78bfa", "short": "Veloz",       "text": "142 de vida, pero empieza con 8 de energía." }
}

const EVENTS := {
	"barajar": { "name": "Barajar", "text": "Cambias 4 de tus 5 cartas por otras al azar. Luego recuperas tu mano." },
	"corta":   { "name": "Mano corta", "text": "Solo puedes jugar 3 de tus 5 cartas." },
	"sobre":   { "name": "Sobrecarga rápida", "text": "La Sobrecarga se activa con racha 2." },
	"coraza":  { "name": "Vida doble", "text": "Todo el daño se reduce a la mitad." },
	"pesado":  { "name": "Golpes pesados", "text": "Todo el daño aumenta 50 %." },
	"ayuno":   { "name": "Recarga doble", "text": "Los dos recuperan el doble de energía por turno." },
	"llena":   { "name": "Energía llena", "text": "Los dos recuperan toda la energía ahora.", "dur": 1 },
	"cambio":  { "name": "Intercambio", "text": "Los dos intercambian su energía actual.", "dur": 1 },
	"racha":   { "name": "Racha regalada", "text": "Los dos ganan +2 de racha ahora.", "dur": 1 },
	"cura":    { "name": "Reparación", "text": "Los dos recuperan 15 % de su vida.", "dur": 1 },
	"colapso": { "name": "Colapso", "text": "Los dos pierden 30 % de su vida actual ahora.", "dur": 1 },
	"desgaste":{ "name": "Desgaste", "text": "Los dos pierden 7 de vida al final de cada turno." },
	"furia":   { "name": "Furia", "text": "Todo el daño se duplica." }
}

const DIFFS := {
	"easy":   { "name": "Fácil",   "text": "Se equivoca seguido y tiene 10% menos de vida.",
	          "over": 0.10, "blunder": 0.70, "foolish": 0.3, "trust": 0,    "explore": 0,    "adapt": false, "smart": false, "econ": false, "hp": 0.90 },
	"normal": { "name": "Normal",  "text": "Cambia de estilo y a veces te lee, tiene 30 % más de vida y golpea +2. Ganarle cuesta (cerca de 28 %).",
	          "over": 0.50, "blunder": 0.10, "foolish": 0,   "trust": 0.5,  "explore": 0,    "adapt": false, "smart": false, "econ": false, "hp": 1.30, "edge": 2 },
	"hard":   { "name": "Difícil", "text": "Aprende cómo juegas, cambia de táctica, cuida su energía, tiene 44 % más de vida y golpea +3. Ganarle es raro (cerca de 20 %).",
	          "over": 1.00, "blunder": 0,    "foolish": 0,   "trust": 0.95, "explore": 0.06, "adapt": true,  "smart": true,  "econ": true,  "hp": 1.44, "edge": 3 }
}
