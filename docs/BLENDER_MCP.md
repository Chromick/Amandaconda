# Blender MCP (gerar / editar personagens)

Integração: [blender-mcp](https://github.com/ahujasid/blender-mcp) ([mcp-for-blender.com](https://mcp-for-blender.com/)).

## O que isso faz (e o que não faz)

**Faz:** controlar o Blender aberto pelo Cursor (modelar, material, import/export glTF, Poly Haven, Sketchfab, Poly Pizza). Com API key: geração AI 3D (Hyper3D Rodin / Hunyuan3D).

**Não faz sozinho:** personagem souls completo com animações de combate prontas pro Godot. Para isso o fluxo do Amandaconda continua sendo Quaternius (ou Mixamo) → glTF → `assets/characters/`.

Use o MCP para: recolorir, posar, limpar mesh, exportar variante de chefe, montar props no Blender e mandar pro `assets/`.

## Setup (já parcialmente feito)

1. **uv** instalado em `%USERPROFILE%\.local\bin`
2. **MCP** em [`.cursor/mcp.json`](../.cursor/mcp.json) (servidor `blender`)
3. **Addon** em  
   `%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\blender_mcp.py`
4. Blender: `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`

## Ativar (você)

1. Abra o **Blender 5.2** uma vez (cria pastas de config).
2. **Edit → Preferences → Add-ons** → busque **MCP for Blender** → enable.
3. No viewport: tecla **N** → aba **MCP for Blender** → **Start MCP Server**.
4. No Cursor: **Settings → MCP** → enable **blender** (ou Reload). Reinicie o Cursor se `uvx` não aparecer.
5. Só uma sessão MCP por vez (Cursor **ou** Claude Desktop).

## Pedidos úteis no chat

- “No Blender, importa `assets/characters/Characters_Matt.gltf` e exporta uma variante recolorida pra `assets/characters/boss_luan.gltf`”
- “Gera um low-poly do bandejão via Poly Pizza / Poly Haven e exporta glTF pro projeto”
- (Com API) “Gera um mesh base de monstro com Rodin e exporta glTF”

## Segurança

O MCP pode rodar Python arbitrário no Blender. Para restringir: `BLENDER_MCP_SAFE_MODE=1` no `env` do `mcp.json`.
