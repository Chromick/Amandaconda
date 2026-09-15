# AUTONOMOUS_PROGRESS

Registro de desenvolvimento autônomo do runtime **Godot 4.7**  
Repo: [Chromick/Amandaconda](https://github.com/Chromick/Amandaconda) · branch `godot-4`  
Toggle: `AUTONOMOUS_MODE.json` (`enabled: true|false`)

---

## 2026-09-15 ~loop v0.6.0

### Alteração
- v0.6.0 checkpoint: FOV stack, Eco burst, heal light, combo finisher, gate/arena/boss juice, stamina regen, revive pop, Amandaconda death punch.

### Testes
- Hub headless EXIT 0 (cada ciclo)

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar até o usuário parar

---
## 2026-09-15 ~continuação loop (v0.5.9)

### Alteração
- v0.5.9: FOV kick stack; Eco burst; heal light; combo finisher flash; gate shrink; invuln fade; school roll ghost; stamina low pulse; menu hover; etc.

### Testes
- Hub headless EXIT 0 (cada ciclo)

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar até o usuário parar

---
## 2026-09-15 ~continuação loop

### Alteração
- v0.5.8: speed_mult refresh fix; pickup double-collect guard; heal snappier; hurt flash; empty-ability toast; roll/heal balance.

### Testes
- Hub headless EXIT 0 (cada ciclo)

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar até o usuário parar

---
## 2026-09-15 ~07:45 BRT

### AlteraÃ§Ã£o
- v0.4.4: camera spring lock/sprint; stamina toast; ability cast juice; Chatana Beach; trash KO shrink; lock marker bob + FOV punch.

### Testes
- Hub headless EXIT 0 (vÃ¡rios ciclos)

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar loop

---

## 2026-09-15 ~08:28 BRT

### AlteraÃ§Ã£o
- Loop contÃ­nuo ativo; v0.4.3; invuln blink; Espelho sparks; gate fade fix; weapon trail; etc.

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar

---

## 2026-09-15 ~08:22 BRT

### AlteraÃ§Ã£o
- Loop contÃ­nuo: trails de vÃ­rus/net, safezone ring, dust, enrage elites, FOV kicks, telegraphs pulsantes, weapon trail melee, etc. (vÃ¡rios commits desde ~07:55).

### Arquivos modificados
- ver `git log` em `godot-4` desde `4de3a86`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0 em cada ciclo

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar atÃ© o usuÃ¡rio parar

---

## 2026-09-15 ~08:16 BRT

### AlteraÃ§Ã£o
- Bytes pickup glow + luz.
- Hit: kick de FOV na cÃ¢mera.
- Lock pulse, Balarrals roll tell, pause version, Renan spark (commits anteriores nesta sessÃ£o).

### Arquivos modificados
- `scripts/world/bytes_pickup.gd`
- `scripts/player/camera_controller.gd`
- `scripts/player/player_controller.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar

---

## 2026-09-15 ~08:12 BRT

### AlteraÃ§Ã£o
- Poeira no jump; ending com flash rosa e toast mais longo.
- v0.4.2 + enrage elites (commit anterior).

### Arquivos modificados
- `scripts/ui/hud.gd`
- `scripts/player/player_controller.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar

---

## 2026-09-15 ~08:10 BRT

### AlteraÃ§Ã£o
- Enrage â‰¤40% HP: Portara, Chatana, Net (mais rÃ¡pidos/agressivos + toast + spark).

### Arquivos modificados
- `scripts/enemies/portara.gd`
- `scripts/enemies/chatana.gd`
- `scripts/enemies/net.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar

---

## 2026-09-15 ~08:06 BRT

### AlteraÃ§Ã£o
- Toast HUD com punch de escala + fade-out.
- Dust motes flutuando no campus (`dust_motes.gd`).

### Arquivos modificados
- `scripts/ui/hud.gd`
- `scripts/world/dust_motes.gd` (novo)
- `scripts/world/campus_builder.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar

---

## 2026-09-15 ~08:02 BRT

### AlteraÃ§Ã£o
- Toast + spark quando a marca da Net dissipar.
- Poeira no sprint.
- Menu: tÃ­tulo pulsante e hover verde nos botÃµes.

### Arquivos modificados
- `scripts/player/player_controller.gd`
- `scripts/ui/main_menu.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub + menu headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar

---

## 2026-09-15 ~07:58 BRT

### AlteraÃ§Ã£o
- VÃ­rus: glow, luz, trail e spark no quique.
- Net shot: glow magenta, luz, look_at, spark no impacto.
- Safezone: anel torus pulsante + spark ao entrar.
- Player: poeira ao pousar apÃ³s salto.

### Arquivos modificados
- `scripts/combat/virus_projectile.gd`
- `scripts/enemies/net_shot.gd`
- `scripts/world/safezone.gd`
- `scripts/player/player_controller.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar sem parar

---

## 2026-09-15 ~07:55 BRT

### AlteraÃ§Ã£o
- Luzes noturnas: flicker com variaÃ§Ã£o de cor quente.
- Damage popup: punch de escala + drift lateral.
- HUD: barra de vida pulsa vermelho abaixo de 30% HP.

### Arquivos modificados
- `scripts/world/light_flicker.gd`
- `scripts/combat/damage_popup.gd`
- `scripts/ui/hud.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar loop (prÃ³ximo turno / prÃ³ximo pedido)

---

## 2026-09-15 ~07:50 BRT

### AlteraÃ§Ã£o
- Inimigos sem respawn: KO fica ~0.45s visÃ­vel antes de `queue_free` (menos â€œpopâ€ seco).

### Arquivos modificados
- `scripts/enemies/enemy_base.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar loop seguro

---

## 2026-09-15 ~07:48 BRT

### AlteraÃ§Ã£o
- CÃ¢mera: FOV dinÃ¢mico â€” +6 no sprint, âˆ’4 no lock-on (lerp suave).

### Arquivos modificados
- `scripts/player/camera_controller.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- SensaÃ§Ã£o visual do FOV: nÃ£o testada em PIE

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar polish (morte de trash fade, luzes, etc.)

---

## 2026-09-15 ~08:10 BRT

### Alteração
- v0.4.5+: hard landing; ability ready flash; Net trail; arena juice; charged heavy FOV; patch shop spark; KB pickups; pendrive light; hack flash.

### Testes
- Hub headless EXIT 0 (vários ciclos)

### Problemas encontrados
- Joãosias AGUARDANDO DECISÃO

### Próxima tarefa
- Continuar

---
## 2026-09-15 ~07:45 BRT

### AlteraÃ§Ã£o
- PoÃ§a de caramelo: material emissivo pulsante, spark no spawn, toast ao pisar (â€œCaramelo Â· movimento lentoâ€).

### Arquivos modificados
- `scripts/bosses/caramel_puddle.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar: FOV sprint / lock-on polish / revisar enemies restantes

---

## 2026-09-15 ~07:42 BRT

### AlteraÃ§Ã£o
- Toast **Cura interrompida** ao tomar dano bebendo lata; limpa telegraph de carga/vÃ­rus no hit.
- Boneco de treino: spark + shake no KO.

### Arquivos modificados
- `scripts/player/player_controller.gd`
- `scripts/enemies/training_dummy.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Loop: ground slow / caramelo feedback, ou polish de cÃ¢mera

---

## 2026-09-15 ~07:38 BRT

### AlteraÃ§Ã£o
- HUD: flash dourado na linha de meta ao ganhar KB.
- Toast `Combo N!` ao encadear leve.
- Carga vÃ­rus: esfera-telegraph que cresce (escola Especial).
- Toast de CD de habilidade com debounce 0.85s (anti-spam).
- VersÃ£o do projeto â†’ **0.4.1**.

### Arquivos modificados
- `scripts/ui/hud.gd`
- `scripts/player/player_controller.gd`
- `project.godot`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Menu + hub headless EXIT 0

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar polish combate / revisar avisos restantes

---

## 2026-09-15 ~07:30 BRT

### AlteraÃ§Ã£o
- **Bosses**: recompensa KB no `balance.json` + `_drop_bytes(false)` na morte (spark; toast de habilidade/progressÃ£o permanece).
- Renanligno passa a carregar `bytes` no `_cfg`.
- **Roll**: afterimages cianos na janela de i-frame (timer morto agora spawna ghosts).
- **PortÃµes**: toast + spark ao liberar.
- **Arena**: nÃ©voa do chefe dissolve com fade ao fim da luta (restaura alpha no re-lock).

### Arquivos modificados
- `data/balance.json`
- `scripts/enemies/enemy_base.gd`
- `scripts/bosses/*.gd` (5 chefs)
- `scripts/player/player_controller.gd`
- `scripts/world/boss_gate.gd`
- `scripts/world/boss_arena.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0 (vÃ¡rias vezes neste ciclo)
- PIE: roll ghosts / boss drop / seal fade â€” nÃ£o testados visualmente

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Combo toast / virus charge telegraph / polish HUD bytes flash

---

## 2026-09-15 ~02:28 BRT

### AlteraÃ§Ã£o
- Pause: dica de controles corretos (Ctrl/C, Shift, Q/MMB, etc.) + painel um pouco mais largo.

### Arquivos modificados
- `scripts/ui/pause_menu.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- Overlay Esc em PIE: nÃ£o testado

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar loop: polimento de combate / feedback de boss reward / revisar TODOs restantes

---

## 2026-09-15 ~02:25 BRT

### AlteraÃ§Ã£o
- Telegraph de **carga do ataque pesado** (cresce com a carga, flash perto do mÃ¡x.); limpa no roll / vigor insuficiente.
- Terminal de patches: bob/rotaÃ§Ã£o, glow prÃ³ximo, toast `[E]`.

### Arquivos modificados
- `scripts/player/player_controller.gd`
- `scripts/world/patch_terminal.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- Charge telegraph / terminal em PIE: nÃ£o testado

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Revisar pause overlay com lista de controles corretos
- Ou juice de morte de boss (KB/bytes no balance se faltar)

---

## 2026-09-15 ~02:18 BRT

### AlteraÃ§Ã£o
- **Bug UI**: hints diziam â€œQ troca armaâ€ / â€œShift rolaâ€, mas Q Ã© lock-on e Shift Ã© sprint; roll Ã© Ctrl/C.
- Hints corrigidos; **MMB** adicionado ao action `lock_on`.

### Arquivos modificados
- `scripts/ui/hud.gd`
- `project.godot`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- MMB/hints em PIE: nÃ£o testado visualmente

### Problemas encontrados
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Continuar juice seguro (pause help, boss reward toast) ou polish terminal

---

## 2026-09-15 ~02:12 BRT

### AlteraÃ§Ã£o
- Drop de KB dos inimigos (Chatana/Net/Portara) unificado em `enemy_base._drop_bytes()` com toast `+N KB`, spark e shake leve (antes era silencioso).

### Arquivos modificados
- `scripts/enemies/enemy_base.gd`
- `scripts/enemies/chatana.gd`
- `scripts/enemies/net.gd`
- `scripts/enemies/portara.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0
- Drop em combate: nÃ£o testado em PIE

### Problemas encontrados
- Bosses sobrescrevem `_die` sem `super` (intencional); recompensa de boss continua sÃ³ via `mark_boss_defeated`
- JoÃ£osias AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Toast ao trocar arma (Q) / polish do terminal de patches
- Revisar feedback de boss reward se houver bytes no balance

---

## 2026-09-15 ~02:05 BRT

### AlteraÃ§Ã£o
- **Pendrive pickup**: spin/bob, cor emissiva por tipo, toast com nÃ­vel Fis/Esp, spark + shake ao coletar.
- **Patch shop**: HitFeel.cancel ao abrir; toast de abertura; slots cheios / KB insuficiente (tooltip + disable); toast com nome do patch ao comprar.
- **Habilidades**: toast de CD (`Eco em recarga Â· Xs`), vigor insuficiente, Caramelo confirmado; telegraph esfÃ©rico do Eco com flash no impacto + spark.
- **HUD**: label de habilidade mostra `CD Xs` em tempo real.
- **Cura**: feedback â€œVida cheiaâ€ / â€œSem latasâ€ / â€œBebendo lataâ€¦â€.

### Arquivos modificados
- `scripts/world/pendrive_pickup.gd`
- `scripts/ui/patch_shop.gd`
- `scripts/player/player_controller.gd`
- `scripts/ui/hud.gd`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless `--quit-after 3` EXIT 0 (Balance OK)
- PIE visual (pendrive/shop/eco telegraph): **nÃ£o** executado

### Problemas encontrados
- Elite JoÃ£osias ainda **AGUARDANDO DECISÃƒO** (sala de spawn)
- Feedback visual fino depende de PIE do usuÃ¡rio

### PrÃ³xima tarefa
- Feedback de roll/ataque sem vigor (toast leve ou sÃ³ flash jÃ¡ existente)
- Revisar terminal/interaÃ§Ãµes E prÃ³ximos juice de combate

---

## 2026-09-15 ~01:50 BRT

### AlteraÃ§Ã£o
- Agente autÃ´nomo com **toggle fÃ¡cil**: `AUTONOMOUS_MODE.json` + rule `.cursor/rules/autonomous-dev.mdc` + doc `docs/AGENTE_AUTONOMO.md`.
- Git do runtime Godot inicializado na branch `godot-4`, remote = Chromick/Amandaconda (sem tocar em `master` Pygame).
- UI: HUD mostra `MARCADO Xs` (magenta) enquanto a mark da Net estÃ¡ ativa.

### Arquivos modificados
- `AUTONOMOUS_MODE.json` (novo)
- `.cursor/rules/autonomous-dev.mdc` (novo)
- `docs/AGENTE_AUTONOMO.md` (novo)
- `scripts/ui/hud.gd`
- `scripts/player/player_controller.gd`
- `.gitignore`
- `AUTONOMOUS_PROGRESS.md`

### Testes
- Hub headless EXIT 0 apÃ³s indicador MARCADO
- `git fetch origin master` OK

### Problemas encontrados
- Push ainda nÃ£o validado nesta entrada (prÃ³ximo passo)
- PIE visual da marca: nÃ£o testado

## 2026-09-15 ~01:55 BRT

### AlteraÃ§Ã£o
- Push da branch `godot-4` para https://github.com/Chromick/Amandaconda/tree/godot-4 (master Pygame intacto).
- HUD: indicador `MARCADO Xs` enquanto mark da Net ativa.
- F5 balance: toast â€œBalance F5 Â· recarregadoâ€.
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
- `git push origin godot-4` â†’ branch criada no GitHub

### Problemas encontrados
- PowerShell reporta exit 1 no push por mensagens `remote:` no stderr; branch foi criada com sucesso

### PrÃ³xima tarefa
- Continuar loop: polish pause/menu ou elite JoÃ£osias (ainda AGUARDANDO DECISÃƒO de sala)
- Opcional: abrir PR `godot-4` â†’ nÃ£o mergear em master sem pedido

---

## HistÃ³rico anterior (bugs SessionUtil / HitFeel / Portara / etc.)

Ver entradas ~01:40â€“01:48 abaixo no arquivo legado; resumo: sparks, SceneUtil, restore/balance, hitstop, mark toast, arena toast, net shot magenta.

## 2026-09-15 01:53 BRT

### AlteraÃ§Ã£o
- AutÃ´nomo confirmado ligado (enabled: true).
- \HitFeel.cancel()\: pause/menu/respawn nÃ£o deixam \	ime_scale\ preso.
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
- PIE pause-durante-hitstop: nÃ£o testado visualmente

### Problemas encontrados
- JoÃ£osias spawn ainda AGUARDANDO DECISÃƒO

### PrÃ³xima tarefa
- Migrar look_at dos bosses/trash para \_face_flat\ onde fizer sentido
- Continuar polish de combate / UI

## 2026-09-15 01:54 BRT

### AlteraÃ§Ã£o
- Trash/bosses passam a usar \_face_flat\ no chase (8 scripts).

### Arquivos modificados
- scripts/enemies/chatana.gd, portara.gd, net.gd
- scripts/bosses/luanevil.gd, renanligno.gd, marlombolico.gd, amandaconda.gd, balarrals.gd

### Testes
- Hub headless EXIT 0; push \godot-4\ OK

### Problemas encontrados
- (nenhum)

### PrÃ³xima tarefa
- UI menu/version ou polish de lock-on distance feedback

## 2026-09-15 01:56 BRT

### AlteraÃ§Ã£o
- Loop contÃ­nuo: vÃ­rus look_at seguro + spark no hit; feedback de lock-on; menu noturno + versÃ£o; toast na safezone; HitFeel cancel ao iniciar run; lock limpa alvo morto.

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

### PrÃ³xima tarefa
- Continuar polish: damage popup no player ao tomar dano, ou telegraph do vÃ­rus

## 2026-09-15 01:57 BRT

### AlteraÃ§Ã£o
- Popup de dano vermelho quando o player toma hit.
- ProjÃ©til vÃ­rus com luz omni + emission mais forte.

### Arquivos modificados
- scripts/player/player_controller.gd
- scenes/virus_projectile.tscn
- AUTONOMOUS_PROGRESS.md

### Testes
- Hub headless EXIT 0

### Problemas encontrados
- (nenhum)

### PrÃ³xima tarefa
- Continuar: heal popup verde / streak de bytes pickup feedback

## 2026-09-15 01:57 BRT

### AlteraÃ§Ã£o
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

### PrÃ³xima tarefa
- Continuar no loop (pendrive pickup / patch shop UX)
