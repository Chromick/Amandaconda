# Mixamo — animações extras (manual)

O Mixamo exige login Adobe; não dá pra baixar automaticamente daqui.

## O que já cobre animações

Os packs Quaternius (Zombie Apocalypse + Modular Men) já trazem Idle/Walk/Run/Attack/Death.  
`CharacterVisual` mapeia aliases estilo Mixamo (`Walking`, `Running`, `Attack1`, etc.).

## Se quiser Mixamo em cima do Matt / Modular

1. Abra https://www.mixamo.com e faça login.
2. Escolha um personagem **ou** faça upload do `Characters_Matt.gltf` / FBX.
3. Baixe animações em **FBX Binary**, *Without Skin* (se o mesh já está no projeto) ou *With Skin* para um pack novo.
4. Coloque os FBX em `assets/mixamo/` (pasta com `.gdignore` se forem só referência).
5. No Godot: importe, copie clips para o AnimationPlayer do player **ou** reexporte glTF com as anims.
6. Nomes recomendados: `Idle`, `Walk`, `Run`, `Jump`, `Roll`/`Duck`, `Slash`, `Stab`, `Death`.

Não substitua o `player_controller.gd` — só a pele de animação.
