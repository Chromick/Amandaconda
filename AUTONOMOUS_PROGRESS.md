# AUTONOMOUS_PROGRESS

Registro de desenvolvimento autônomo do runtime **Godot 4.7**  
Repo: [Chromick/Amandaconda](https://github.com/Chromick/Amandaconda) · branch `godot-4`  
Toggle: `AUTONOMOUS_MODE.json` (`enabled: true|false`)

---

## 2026-09-15 ~07:45 BRT

### Alteração
- Poça de caramelo: material emissivo pulsante, spark no spawn, toast ao pisar (“Caramelo · movimento lento”).

### Arquivos modificados
- `scripts/bosses/caramel_puddle.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar: FOV sprint / lock-on polish / revisar enemies restantes

---

## 2026-09-15 ~07:42 BRT

### Alteração
- Toast **Cura interrompida** ao tomar dano bebendo lata; limpa telegraph de carga/vírus no hit.
- Boneco de treino: spark + shake no KO.

### Arquivos modificados
- `scripts/player/player_controller.gd`
- `scripts/enemies/training_dummy.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Loop: ground slow / caramelo feedback, ou polish de câmera

---

## 2026-09-15 ~07:38 BRT

### Alteração
- HUD: flash dourado na linha de meta ao ganhar KB.
- Toast `Combo N!` ao encadear leve.
- Carga vírus: esfera-telegraph que cresce (escola Especial).
- Toast de CD de habilidade com debounce 0.85s (anti-spam).
- Versão do projeto → **0.4.1**.

### Arquivos modificados
- `scripts/ui/hud.gd`
- `scripts/player/player_controller.gd`
- `project.godot`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Menu + hub headless EXIT 0

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar polish combate / revisar avisos restantes

---

## 2026-09-15 ~07:30 BRT

### Alteração
- **Bosses**: recompensa KB no `balance.json` + `_drop_bytes(false)` na morte (spark; toast de habilidade/progressão permanece).
- Renanligno passa a carregar `bytes` no `_cfg`.
- **Roll**: afterimages cianos na janela de i-frame (timer morto agora spawna ghosts).
- **Portões**: toast + spark ao liberar.
- **Arena**: névoa do chefe dissolve com fade ao fim da luta (restaura alpha no re-lock).

### Arquivos modificados
- `data/balance.json`
- `scripts/enemies/enemy_base.gd`
- `scripts/bosses/*.gd` (5 chefs)
- `scripts/player/player_controller.gd`
- `scripts/world/boss_gate.gd`
- `scripts/world/boss_arena.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0 (várias vezes neste ciclo)
- PIE: roll ghosts / boss drop / seal fade — não testados visualmente

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Combo toast / virus charge telegraph / polish HUD bytes flash

---

## 2026-09-15 ~02:28 BRT

### Alteração
- Pause: dica de controles corretos (Ctrl/C, Shift, Q/MMB, etc.) + painel um pouco mais largo.

### Arquivos modificados
- `scripts/ui/pause_menu.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- Overlay Esc em PIE: não testado

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar loop: polimento de combate / feedback de boss reward / revisar TODOs restantes

---

## 2026-09-15 ~02:25 BRT

### Alteração
- Telegraph de **carga do ataque pesado** (cresce com a carga, flash perto do máx.); limpa no roll / vigor insuficiente.
- Terminal de patches: bob/rotação, glow próximo, toast `[E]`.

### Arquivos modificados
- `scripts/player/player_controller.gd`
- `scripts/world/patch_terminal.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- Charge telegraph / terminal em PIE: não testado

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Revisar pause overlay com lista de controles corretos
- Ou juice de morte de boss (KB/bytes no balance se faltar)

---

## 2026-09-15 ~02:18 BRT

### Alteração
- **Bug UI**: hints diziam “Q troca arma” / “Shift rola”, mas Q é lock-on e Shift é sprint; roll é Ctrl/C.
- Hints corrigidos; **MMB** adicionado ao action `lock_on`.

### Arquivos modificados
- `scripts/ui/hud.gd`
- `project.godot`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- MMB/hints em PIE: não testado visualmente

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar juice seguro (pause help, boss reward toast) ou polish terminal

---

## 2026-09-15 ~02:12 BRT

### Alteração
- Drop de KB dos inimigos (Chatana/Net/Portara) unificado em `enemy_base._drop_bytes()` com toast `+N KB`, spark e shake leve (antes era silencioso).

### Arquivos modificados
- `scripts/enemies/enemy_base.gd`
- `scripts/enemies/chatana.gd`
- `scripts/enemies/net.gd`
- `scripts/enemies/portara.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- Drop em combate: não testado em PIE

### Problemas encontrados
- Bosses sobrescrevem `_die` sem `super` (intencional); recompensa de boss continua só via `mark_boss_defeated`
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Toast ao trocar arma (Q) / polish do terminal de patches
- Revisar feedback de boss reward se houver bytes no balance

---

## 2026-09-15 ~02:05 BRT

### Alteração
- **Pendrive pickup**: spin/bob, cor emissiva por tipo, toast com nível Fis/Esp, spark + shake ao coletar.
- **Patch shop**: HitFeel.cancel ao abrir; toast de abertura; slots cheios / KB insuficiente (tooltip + disable); toast com nome do patch ao comprar.
- **Habilidades**: toast de CD (`Eco em recarga · Xs`), vigor insuficiente, Caramelo confirmado; telegraph esférico do Eco com flash no impacto + spark.
- **HUD**: label de habilidade mostra `CD Xs` em tempo real.
- **Cura**: feedback “Vida cheia” / “Sem latas” / “Bebendo lata…”.

### Arquivos modificados
- `scripts/world/pendrive_pickup.gd`
- `scripts/ui/patch_shop.gd`
- `scripts/player/player_controller.gd`
- `scripts/ui/hud.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless `--quit-after 3` EXIT 0 (Balance OK)
- PIE visual (pendrive/shop/eco telegraph): **não** executado

### Problemas encontrados
- Elite Joãosias ainda **AGUARDANDO DECISÃO** (sala de spawn)
- Feedback visual fino depende de PIE do usuário

### Próxima tarefa
- Feedback de roll/ataque sem vigor (toast leve ou só flash já existente)
- Revisar terminal/interações E próximos juice de combate

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

## 2026-09-15 01:54 BRT

### Alteração
- Trash/bosses passam a usar \_face_flat\ no chase (8 scripts).

### Arquivos modificados
- scripts/enemies/chatana.gd, portara.gd, net.gd
- scripts/bosses/luanevil.gd, renanligno.gd, marlombolico.gd, amandaconda.gd, balarrals.gd

### Testes
- Hub headless EXIT 0; push \godot-4\ OK

### Problemas encontrados
- (nenhum)

### Próxima tarefa
- UI menu/version ou polish de lock-on distance feedback

## 2026-09-15 01:56 BRT

### Alteração
- Loop contínuo: vírus look_at seguro + spark no hit; feedback de lock-on; menu noturno + versão; toast na safezone; HitFeel cancel ao iniciar run; lock limpa alvo morto.

### Arquivos modificados
- scripts/combat/virus_projectile.gd
- scripts/player/player_controller.gd
- scripts/autoload/game_state.gd
- scripts/ui/main_menu.gd
- scripts/world/safezone.gd
- AUTONOMOUS_PROGRESS.md

### Testes
- Hub + main_menu headless EXIT 0

### Problemas encontrados
- (nenhum novo)

### Próxima tarefa
- Continuar polish: damage popup no player ao tomar dano, ou telegraph do vírus

## 2026-09-15 01:57 BRT

### Alteração
- Popup de dano vermelho quando o player toma hit.
- Projétil vírus com luz omni + emission mais forte.

### Arquivos modificados
- scripts/player/player_controller.gd
- scenes/virus_projectile.tscn
- AUTONOMOUS_PROGRESS.md

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- (nenhum)

### Próxima tarefa
- Continuar: heal popup verde / streak de bytes pickup feedback

## 2026-09-15 01:57 BRT

### Alteração
- Cura de lata: popup verde + spark (safezone drip sem spam).
- Bytes pickup: spin/bob, toast \+N KB\, spark dourado.

### Arquivos modificados
- scripts/player/player_controller.gd
- scripts/world/bytes_pickup.gd
- AUTONOMOUS_PROGRESS.md

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- (nenhum)

### Próxima tarefa
- Continuar no loop (pendrive pickup / patch shop UX)
