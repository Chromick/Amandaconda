# AMANDACONDA

Action soulslike **3D** em Godot 4.7 (Forward Plus + Jolt): campus semiaberto estilo Elden Ring — exploração, chefes-base quando você aguentar, e ela na porta.

> Você anda pela faculdade à noite. Os três chefes-base estão no mapa. Pode ir cedo.
> Vai doer. Mata eles, libera o Marlon, depois a saída.
>
> A Amandaconda está encostada na porta, fumando, com um café na mão. Esperando.

**Runtime oficial: este projeto Godot.**  
Pygame (2D) e Unreal (`D:\AmandacondaUE`) são referência de design / arquivo morto — não rode o jogo por eles.

## Abrir no Godot 4.7

1. Instale / use **Godot 4.7+** (testado: `4.7.2-stable` win64).
2. No Project Manager: **Import** → selecione `project.godot` nesta pasta.
3. Confirme renderer **Forward Plus** e física **Jolt** (já no `project.godot`).

Caminho local do editor usado no MCP:

`C:\Users\bruno\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`

## Rodar

- No editor: **F5** (cena principal = `scenes/main_menu.tscn`).
- Ou CLI:

```bat
"C:\Users\bruno\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path . --main-pack
```

Mais simples:

```bat
godot --path .
```

(se `godot` estiver no PATH; senão use o `.exe` completo acima com `--path "C:\Users\bruno\OneDrive\Documentos\amandaconda"`)

No menu: escolha **Físico (Teclado)** ou **Especial (Vírus)** → campus hub com salas, inimigos e bosses.

## Controles

| Input | Ação |
|---|---|
| `W` `A` `S` `D` / setas | Mover (relativo à câmera) |
| `Shift` | Correr |
| `Espaço` | Pular |
| `Ctrl` ou `C` | Rolamento (gasta vigor, i-frames) |
| Mouse esquerdo / `J` | Ataque leve (melee ou vírus) |
| Mouse direito / `L` (segurar) | Ataque pesado / carga |
| `R` | Beber lata de energético (canaliza; pode ser punido) |
| `F` | Usar habilidade de chefe equipada |
| `T` | Trocar habilidade (só na safezone) |
| `E` | Servidor de backup (Patches) |
| `Q` | Lock-on no alvo próximo |
| `Esc` | Pause / liberar mouse |
| `F5` | Recarregar `data/balance.json` |

## O que já está aqui vs o que falta

**Já funciona (v0.4)**

- Conceito + `data/balance.json` (metros 3D)
- Autoloads `Balance`, `GameState`, `HitFeel`
- Menu com escolas Físico / Especial
- Player 3D: move, roll, ataques, cura (latas), mark da Net, slow de caramelo, respawn na safezone
- Mesh Quaternius (Matt) no player + props Kenney no hall / bandejão / lab / servidores
- Animações Quaternius (Idle/Walk/Run/ataque/morte) no player, inimigos e bosses
- Inimigos/bosses com mesh (zombies + Shaun/Lis/Matt) em vez de cápsula pura
- Campus blockout: hall safe + 5 salas (bandejão, lab, pátio, servidores, porta) + corredores
- Inimigos: Chatana, Portara, **Net** (marcam + projétil), drops de Bytes
- Bosses jogáveis: **LuanEvil**, **Renanligno**, **Balarrals**, **Marlombólico**, **Amandaconda**
- Habilidades roubadas: **Caramelo / Eco / Espelho** (equipa na safe com `T`, usa com `F`)
- Gates: 3 chefes-base → servidores; Marlon → porta
- Pendrives + Servidor de Backup (Patches)
- HUD: toast, barra de boss no lock-on, aviso de hack

**Ainda falta**

1. BlendTree fino (transições) + áudio
2. Ending screen dedicada
3. Polish de telegraphs / VFX de golpe

## Créditos de assets (CC0)

- [Kenney](https://kenney.nl) — Furniture, Building, Factory, **City Kit** (`assets/props/`, `assets/props/city/`)
- [Quaternius](https://quaternius.com) — Zombie Apocalypse + Ultimate Modular Men (`assets/characters/`)
- Mixamo (opcional, manual): [docs/MIXAMO.md](docs/MIXAMO.md)

## MCP Godot (Cursor)

Arquivo: [`.cursor/mcp.json`](.cursor/mcp.json)

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "godot-mcp-runtime"],
      "env": {
        "GODOT_PATH": "C:\\Users\\bruno\\Downloads\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64.exe"
      }
    }
  }
}
```

**Ativar:** Cursor Settings → MCP → enable **godot** (ou Reload). Precisa de Node/`npx` no PATH. Se o `.exe` mudar de pasta, atualize `GODOT_PATH`.

## Estrutura

```
scenes/          menu, hub_arena, player, enemies, bosses
scripts/         player, camera, combat/UI, world (campus + props), autoloads
assets/props/    Kenney GLB curados (móveis, caixas, pipes)
assets/characters/ Quaternius glTF (Matt, Lis, Shaun, zombies)
data/balance.json
docs/            GDD, ARTE, NUMEROS (+ arte de referência)
```

## Os cinco

| Chefe | Onde (design) |
|---|---|
| **LuanEvil** | Bandejão |
| **Renanligno** | Laboratório |
| **Balarrals** | Pátio |
| **Marlombólico** | Servidores |
| **AMANDACONDA** | A porta |

Detalhe de design: [docs/GDD.md](docs/GDD.md). Números: [docs/NUMEROS.md](docs/NUMEROS.md) + `data/balance.json`.  
Inspiração de feel (não drop-in): [docs/TEMPLATES.md](docs/TEMPLATES.md).  
Blender MCP (editar/gerar meshes): [docs/BLENDER_MCP.md](docs/BLENDER_MCP.md).
