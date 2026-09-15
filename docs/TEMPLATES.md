# Templates externos — o que aproveitamos

Referência só de **padrões**. O controller do Amandaconda permanece nosso (escolas, latas, bosses, balance.json).

## Fontes

1. [Third Person Controller Template — Melee-Souls-Like](https://godotengine.org/asset-library/asset/1377)  
   Repo: [pemguin005/Third-Person-Controller---Godot-Souls-like](https://github.com/pemguin005/Third-Person-Controller---Godot-Souls-like) (Godot **3.4**, MIT)

2. [Godot 4 Souls-Like Template](https://godotengine.org/asset-library/asset/2609)  
   Repo: [catprisbrey/Cats-Godot4-Modular-Souls-like-Template](https://github.com/catprisbrey/Cats-Godot4-Modular-Souls-like-Template) (Godot **4.2**, Unlicense)

Clones locais (não versionados): `assets/_download/templates/`

## Por que não plugar o projeto inteiro

| Template | Motivo |
|---|---|
| Melee 1377 | Godot 3 (`KinematicBody`, API antiga). AnimTree do demo não casa com Quaternius. |
| Souls 2609 | Sistema monolítico (equipment, ladder, root motion, signals). Sobrescreveria balance/escolas/habilidades. |

## O que trouxemos (inspiração)

**Do melee (prioridade do usuário):**
- Aceleração/fricção mais “lerp” no movimento
- Combo leve 1→2 (Slash → Punch)
- Sprint + ataque leve = dash + golpe pesado rápido
- Roll + ataque = mesmo dash-golpe
- Câmera auto-yaw atrás do player quando o mouse fica idle

**Do souls Godot 4:**
- Inimigos às vezes recuam / orbitam antes de atacar (`combat_randomizer` feel)
- Manter animação dirigida por estado (já no `CharacterVisual`), sem root motion por enquanto

## Próximos passos opcionais

- AnimationTree real (OneShot Attack + conditions IsWalking/IsRunning) no Matt
- Parry window mais curta estilo template (Espelho já cobre parte)
- NavigationAgent em bosses grandes
