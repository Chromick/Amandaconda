# AUTONOMOUS_PROGRESS

Registro de desenvolvimento autônomo do runtime **Godot 4.7**  
Repo: [Chromick/Amandaconda](https://github.com/Chromick/Amandaconda) · branch `godot-4`  
Toggle: `AUTONOMOUS_MODE.json` (`enabled: true|false`)

---

## 2026-09-15 ~01:50 BRT

### Alteração
- Agente autônomo com **toggle fácil**: `AUTONOMOUS_MODE.json` + rule `.cursor/rules/autonomous-dev.mdc` + doc `docs/AGENTE_AUTONOMO.md`.
- Git do runtime Godot inicializado na branch `godot-4`, remote = Chromick/Amandaconda (sem tocar em `master` Pygame).
- UI: HUD mostra `MARCADO Xs` (magenta) enquanto a mark da Net está ativa.

### Arquivos modificados
- `AUTONOMOUS_MODE.json` (novo)
- `.cursor/rules/autonomous-dev.mdc` (novo)
- `docs/AGENTE_AUTONOMO.md` (novo)
- `scripts/ui/hud.gd`
- `scripts/player/player_controller.gd`
- `.gitignore`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0 após indicador MARCADO
- `git fetch origin master` OK

### Problemas encontrados
- Push ainda não validado nesta entrada (próximo passo)
- PIE visual da marca: não testado

## 2026-09-15 ~01:55 BRT

### Alteração
- Push da branch `godot-4` para https://github.com/Chromick/Amandaconda/tree/godot-4 (master Pygame intacto).
- HUD: indicador `MARCADO Xs` enquanto mark da Net ativa.
- F5 balance: toast “Balance F5 · recarregado”.
- Agente toggle documentado e ativo (`AUTONOMOUS_MODE.json`).

### Arquivos modificados
- `scripts/ui/hud.gd`
- `scripts/player/player_controller.gd`
- `scripts/autoload/balance.gd`
- `AUTONOMOUS_MODE.json`
- `.cursor/rules/autonomous-dev.mdc`
- `docs/AGENTE_AUTONOMO.md`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- `git push origin godot-4` → branch criada no GitHub

### Problemas encontrados
- PowerShell reporta exit 1 no push por mensagens `remote:` no stderr; branch foi criada com sucesso

### Próxima tarefa
- Continuar loop: polish pause/menu ou elite Joãosias (ainda AGUARDANDO DECISÃO de sala)
- Opcional: abrir PR `godot-4` → não mergear em master sem pedido

---

## Histórico anterior (bugs SessionUtil / HitFeel / Portara / etc.)

Ver entradas ~01:40–01:48 abaixo no arquivo legado; resumo: sparks, SceneUtil, restore/balance, hitstop, mark toast, arena toast, net shot magenta.

## 2026-09-15 01:53 BRT

### Alteração
- Autônomo confirmado ligado (enabled: true).
- \HitFeel.cancel()\: pause/menu/respawn não deixam \	ime_scale\ preso.
- Respawn limpa mark, slow, eco e hacks.
- \enemy_base._face_flat()\: look_at XZ seguro no retorno ao spawn.

### Arquivos modificados
- scripts/combat/hit_feel.gd
- scripts/ui/pause_menu.gd
- scripts/player/player_controller.gd
- scripts/autoload/game_state.gd
- scripts/enemies/enemy_base.gd
- AUTONOMOUS_PROGRESS.md

### Testes
- Hub headless EXIT 0
- PIE pause-durante-hitstop: não testado visualmente

### Problemas encontrados
- Joãosias spawn ainda AGUARDANDO DECISÃO

### Próxima tarefa
- Migrar look_at dos bosses/trash para \_face_flat\ onde fizer sentido
- Continuar polish de combate / UI
