"""Constantes de apresentacao e do laco principal.

Nada aqui e balanceamento de jogo. Valores ajustaveis vivem em data/balance.json.
"""

TITLE = "AMANDACONDA"

INTERNAL_WIDTH = 480
INTERNAL_HEIGHT = 270
WINDOW_SCALE = 4

# Passo fixo: toda logica roda a 60 Hz independente da taxa de quadros da maquina.
# E isso que faz os tempos medidos aqui continuarem validos na fase 2, na Unreal.
FIXED_DT = 1.0 / 60.0

# Teto de tempo por quadro. Sem isso, um travamento longo faria a simulacao
# tentar recuperar centenas de passos de uma vez e travar de vez.
MAX_FRAME_TIME = 0.25

RENDER_FPS_CAP = 240

COLOR_BG = (16, 14, 20)
COLOR_SOLID = (46, 43, 56)
COLOR_SOLID_TOP = (68, 63, 82)
COLOR_PLAYER = (226, 221, 210)
COLOR_DEBUG = (120, 116, 132)
COLOR_DEBUG_WARN = (198, 122, 96)

# Paleta da Amandaconda: verde-petroleo e ambar. Cada chefe tera a sua,
# mas a interface do jogo usa a dela. Ver docs/GDD.md, secao 11.
COLOR_ACCENT = (216, 158, 74)
COLOR_ACCENT_DEEP = (38, 96, 94)
COLOR_UI_TEXT = (200, 194, 184)
COLOR_UI_TEXT_DIM = (110, 106, 118)
COLOR_UI_SHADOW = (8, 7, 10)
COLOR_UI_PANEL = (28, 25, 38)
COLOR_UI_PANEL_EDGE = (46, 43, 56)

MENU_BG_DARKEN = 150

# Combate. Preparacao tem cor propria porque ela e a informacao mais
# importante da tela: e o aviso que o jogador tem para reagir.
COLOR_PREPARACAO = (198, 122, 96)
COLOR_DANO = (199, 74, 62)
COLOR_INIMIGO = (150, 96, 110)
COLOR_CAIXA_ACERTO = (216, 158, 74)
COLOR_CAIXA_CORPO = (78, 155, 149)
COLOR_VIRUS = (107, 240, 140)
COLOR_VIRUS_CORE = (35, 163, 74)
COLOR_SAFEZONE = (28, 52, 48)
COLOR_SAFEZONE_TOP = (38, 96, 94)
