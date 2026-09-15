# AMANDACONDA — Tabela de ajuste

Este é o documento mais valioso do projeto: tempos e custos atravessam engines.

**Runtime atual:** Godot 4.7 3D (`data/balance.json`, unidades em **metros** / segundos).
Pygame 2D e Unreal ficam só como histórico de descoberta de feeling.

## Por que ele existe

Num soulslike, o que separa um chefe justo de um chefe injusto não é o design — é o
**tempo**. Meio segundo de preparação a mais e o golpe fica legível; meio segundo a menos e
o jogador jura que o jogo trapaceou.

Descobrir esses valores é a parte mais demorada de fazer o gênero. E eles **não dependem de
engine** (exceto escala espacial: pixels → metros).

## A regra de arquitetura

**Nenhum número de balanceamento no meio do código de gameplay.**

Todos os valores vivem em `data/balance.json`. O autoload `Balance` lê de lá.

1. Ajustar o jogo vira editar um arquivo
2. `F5` no jogo recarrega o JSON sem reiniciar
3. Tempos em **segundos**; distâncias em **metros** no Godot

---

## Jogador (Godot 3D)

| Valor | Godot | Observação |
|---|---|---|
| Vida máxima | 100 | `player.max_health` |
| Velocidade caminhada / corrida | 5.3 / 8.8 m/s | convertidos do protótipo |
| Vigor máx / regen / delay | 100 / 40/s / 0.7 s | |
| Rolamento duração / i-frames / custo | 0.42 / 0.05+0.26 / 25 | |
| Ataque leve prep/hit/recover | 0.09 / 0.07 / 0.2 | teclado |
| Ataque pesado | 0.26 / 0.1 / 0.38 | carga até 0.7 s |

Valores vivos: [`data/balance.json`](../data/balance.json).

## Modelo por chefe

Repetir para LuanEvil, Renanligno, Balarrals, Marlombólico e Amandaconda.

| Valor | Godot | Observação |
|---|---|---|
| Vida | — | stubs em `chefes.*` |
| Limiar de mudança de fase | — | % de vida |
| Por ataque: preparação | — | **número mais importante** |
| Janela de acerto / recuperação | — | s |
| Dano | — | |
