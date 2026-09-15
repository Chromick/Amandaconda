# AMANDACONDA — Tabela de ajuste

Este é o documento mais valioso do projeto e o único que atravessa as duas fases inteiro.

## Por que ele existe

Num soulslike, o que separa um chefe justo de um chefe injusto não é o design — é o
**tempo**. Meio segundo de preparação a mais e o golpe fica legível; meio segundo a menos e
o jogador jura que o jogo trapaceou.

Descobrir esses valores é a parte mais demorada de fazer o gênero. E eles **não dependem de
engine**. Se a chicotada de cauda precisa de 0,55 s de preparação pra ser lida a tempo, ela
precisa disso em Pygame e precisa disso na Unreal.

Então: **a fase 1 descobre os números, a fase 2 copia.** Você chega na Unreal sem uma única
dúvida de balanceamento.

## A regra de arquitetura que faz isso funcionar

**Nenhum número desta tabela pode estar escrito no meio do código.**

Todos os valores vivem num arquivo de dados separado (`data/balance.json` ou um módulo
`balance.py` só com constantes). O código lê de lá. Isso te dá três coisas:

1. Ajustar o jogo vira editar um arquivo, sem caçar número no meio da lógica
2. A tabela abaixo é gerada a partir do arquivo, não digitada à mão
3. Portar pra Unreal vira transcrever uma tabela, não reler o código inteiro

**Segunda regra:** todo tempo é medido em **segundos**, nunca em quadros. Quadro depende de
taxa de atualização; segundo não. Use passo de tempo fixo a 60 Hz no laço principal do
Pygame, e todas as durações em segundos de ponto flutuante.

---

## Jogador

| Valor | Pygame | Unreal | Observação |
|---|---|---|---|
| Vida máxima | — | — | |
| Velocidade de caminhada | — | — | unidades/s |
| Velocidade de corrida | — | — | unidades/s |
| Vigor máximo | — | — | |
| Regeneração de vigor | — | — | por segundo, parado |
| Atraso antes de regenerar | — | — | s após a última ação |
| **Rolamento** | | | |
| Duração total | — | — | s |
| Invencibilidade — início | — | — | s após o input |
| Invencibilidade — duração | — | — | s |
| Custo de vigor | — | — | |
| **Ataque leve** | | | |
| Preparação | — | — | s |
| Janela de acerto | — | — | s |
| Recuperação | — | — | s |
| Dano | — | — | |
| Custo de vigor | — | — | |
| Janela de encadeamento | — | — | s para emendar o próximo |
| **Ataque pesado** | | | |
| Preparação | — | — | s |
| Preparação com carga máxima | — | — | s |
| Janela de acerto | — | — | s |
| Recuperação | — | — | s |
| Dano / dano carregado | — | — | |
| Custo de vigor | — | — | |
| **Cura** | | | |
| Quantidade por tentativa | — | — | unidades de item |
| Tempo de uso | — | — | s |
| Vida recuperada | — | — | |

## Modelo por chefe

Repetir este bloco para LuanEvil, Renanligno, Balarrals, Marlombólico e Amandaconda.

| Valor | Pygame | Unreal | Observação |
|---|---|---|---|
| Vida | — | — | |
| Limiar de mudança de fase | — | — | % de vida |
| Resistência a atordoamento | — | — | dano acumulado até cambalear |
| Duração do atordoamento | — | — | s de janela de crítico |
| **Por ataque** | | | |
| Preparação | — | — | s — **o número mais importante da tabela** |
| Janela de acerto | — | — | s |
| Recuperação | — | — | s |
| **Janela de punição** | — | — | s livres depois do combo |
| Dano | — | — | |
| Distância de alcance | — | — | |
| Tempo mínimo entre ataques | — | — | s |

## Bytes / KB

| Valor | Pygame | Unreal | Observação |
|---|---|---|---|
| Drop Chatana | 24–40 | — | `balance.bytes.chatana` |
| Drop Portara | 48–72 | — | |
| Drop Net | 32–56 | — | |
| Slots de Patch | 3 | — | playthrough |
| Custo Patch comum | — | — | preencher ao criar catálogo |
| Custo Driver | — | — | meta permanente |

HUD mostra `N KB` (ou `N.N MB` se ≥ 1024).

## Como preencher

Preencha a coluna Pygame durante a fase 1, ajustando até a luta parecer justa. Só depois de
testar com outra pessoa é que o número está pronto.

O teste que importa: quando o jogador morre, ele precisa saber **o que ele fez de errado**.
Se ele diz "não deu pra ver vindo", aumente a preparação. Se ele diz "eu ataquei e não deu
tempo", aumente a janela de punição. Se ele diz "esse chefe é difícil mas é justo", trave o
número e não mexa mais.

A coluna Unreal existe porque um punhado de valores vai precisar de ajuste na conversão pra
3D — principalmente distância e alcance, que mudam de significado. Tempo quase nunca muda.
