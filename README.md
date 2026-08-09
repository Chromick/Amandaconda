# AMANDACONDA

Soulslike reduzido: uma faculdade à noite, quatro minichefes, e ela na porta.

> Você atravessa a faculdade apanhando, morre dezenas de vezes, derruba os quatro, e chega na
> saída. A Amandaconda está encostada na porta, fumando, com um café na mão. Esperando.
>
> Tudo que você acabou de passar, pra ela, foi o tempo de um cigarro.

Este projeto é uma homenagem a um grupo de amigos. Os quatro minichefes são eles, virados em
versões monstruosas da própria personalidade. A Amandaconda é a quinta, e é a única que não é
piada.

## Duas fases

O mesmo jogo, construído duas vezes. A fase 1 é o protótipo da fase 2 — e os valores de
balanceamento descobertos lá atravessam inteiros.

| | Fase 1 | Fase 2 |
|---|---|---|
| Ferramenta | Pygame, Python | Unreal Engine 5, só Blueprint |
| Dimensão | 2D, vista lateral | 3D, terceira pessoa |
| Arte | Pixel art | Assets de biblioteca gratuita |
| Prazo | ~8 semanas | ~8 semanas |

## Os cinco

| | Onde | O que ensina |
|---|---|---|
| **LuanEvil** | Bandejão em greve | Tanque imparável, sempre sorrindo. O chão enche de caramelo grudento até você não ter onde rolar. Na metade, ela põe o headphone e a música estoura. |
| **Renanligno** | Laboratório | Ataca fora do tempo. Os fantasmas atrasados dele fazem o golpe antes do corpo — a leitura é justa, resistir ao reflexo é que não é. |
| **Balarrals** | Pátio | O espelho. Usa o seu moveset, com a arma na mão trocada. |
| **Marlombólico** | Sala dos servidores | Hackeia o jogo: inverte controles, esconde sua vida, mente na interface. Luta de chinelo, com uma mão no bolso. |
| **AMANDACONDA** | A porta | Duas fases. A única com tratamento de chefe completo. |

## Os inimigos comuns

A infraestrutura da faculdade, viva e hostil. **Chatana** faz um barulho que atrapalha sua
percepção. **Portara** é um muro lento que bloqueia corredor. **Net** é uma antena que te
marca à distância.

## Estado do projeto

Conceito e arte fechados. Fase 1 em andamento — semana 1: motor, movimento e colisão.

## Como rodar

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

**No menu**

| Tecla | |
|---|---|
| `W` `S` ou setas | Navegar |
| `←` `→` | Mudar valor (em Configurações) |
| `Enter` ou `Espaço` | Confirmar |
| `Esc` | Voltar |

**Na abertura**

| Tecla | |
|---|---|
| `Enter` (segurar) | Acelerar a rolagem |
| `Esc` | Pular direto para o jogo |

O texto da abertura fica em [`data/intro.txt`](data/intro.txt) e pode ser reescrito sem mexer
em código. Linha começando com `>` sai destacada, com `=` sai como título, e com `#` é
comentário que não aparece. A velocidade fica em `data/balance.json`, seção `intro` — dá para
ajustar com `F5` no meio da rolagem.

**No jogo**

| Tecla | |
|---|---|
| `A` `D` ou setas | Andar |
| `Shift` | Correr |
| `Espaço` | Pular (soltar cedo encurta o pulo) |
| `Esc` | Voltar ao menu |

**Sempre**

| Tecla | |
|---|---|
| `F5` | Recarregar `data/balance.json` sem fechar o jogo |
| `F1` | Mostrar/esconder informações de depuração |
| `F11` | Alternar tela cheia |

O jogo detecta a resolução do monitor ao abrir e escolhe sozinho a maior ampliação inteira que
cabe. Em Configurações dá para ver o que foi detectado e forçar outra escala. `window_scale: 0`
em `data/settings.json` significa automático.

Ajuste os valores em `data/balance.json` com o jogo aberto e aperte `F5` para ver o efeito na
hora. Os números que você travar aqui vão para [docs/NUMEROS.md](docs/NUMEROS.md) e depois
para a fase 2.

Para conferir que nada quebrou sem abrir a janela:

```bash
.venv\Scripts\python.exe tools\smoke_test.py
```

Para saber o que os números de movimento realmente produzem — altura do pulo, tempo no ar,
quanto você avança num pulo correndo — em vez de julgar no olho:

```bash
.venv\Scripts\python.exe tools\medir_pulo.py
```

Passando outro arquivo de balanceamento como argumento, dá para comparar dois ajustes lado a
lado antes de decidir qual vai para [docs/NUMEROS.md](docs/NUMEROS.md).

## Documentos

- [Documento de Design](docs/GDD.md) — independente de engine: combate, chefes, mapa, final
- [Especificação de arte](docs/ARTE.md) — tamanhos, paleta, quadros e o que desenhar primeiro
- [Fase 1 — Pygame](docs/ROADMAP-pygame.md) — plano de 8 semanas
- [Fase 2 — Unreal](docs/ROADMAP-unreal.md) — plano de 8 semanas
- [Tabela de ajuste](docs/NUMEROS.md) — os números que atravessam as duas fases
- [Arte de conceito](docs/arte/) — os cinco chefes e a cena da porta
- [Conceitos descartados](docs/arquivo/) — a primeira versão, de terror em primeira pessoa
