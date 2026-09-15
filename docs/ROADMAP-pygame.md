# AMANDACONDA — Fase 1: Pygame 2D

**Prazo:** ~8 semanas
**Entrega:** o jogo completo, cinco chefes, do começo ao fim
**Perspectiva:** vista lateral
**Arte:** pixel art
**Equipe:** 1 pessoa

---

## O que esta fase realmente é

Não é uma tarefa separada que você entrega e esquece. **É o protótipo da fase 2.**

O jeito profissional de fazer jogo é prototipar num meio barato, descobrir o que é divertido,
e só então produzir. Sua disciplina está te obrigando a fazer exatamente isso, o que é uma
vantagem que quase nenhum aluno tem.

Você chega na Unreal sem uma única dúvida de design — e principalmente, com a
[tabela de ajuste](NUMEROS.md) preenchida.

## Referências

**Salt and Sanctuary** é a referência exata: Dark Souls em vista lateral, feito por duas
pessoas. **Cuphead** pra estrutura de sequência de chefes. **Hollow Knight** pra sensação de
combate e legibilidade de telegrafia.

## As duas regras técnicas inegociáveis

**1. Passo de tempo fixo a 60 Hz, e todo tempo medido em segundos.**
Nunca em quadros. Quadro depende da máquina; segundo não. Isso é o que garante que os
números descobertos aqui funcionem igual na Unreal.

**2. Nenhum valor de balanceamento escrito no meio do código.**
Tudo em `data/balance.json` ou num módulo só de constantes. Ajustar o jogo vira editar um
arquivo, e portar pra fase 2 vira transcrever uma tabela. Ver [NUMEROS.md](NUMEROS.md).

## O plano de 8 semanas

### Semana 1 — Motor e movimento

Janela, laço principal com passo fixo, resolução interna baixa escalada pra tela cheia,
sprite retangular colorido, andar, correr, pular, gravidade, colisão com chão e plataforma,
câmera seguindo o jogador.

Sem arte nenhuma. Retângulos coloridos.

### Semana 2 — Combate no teclado contra um boneco

Ataque leve/pesado, rolamento, vigor, vida, tranco, HUD. O teclado é a arma de perto.
**MARCO:** alguém bate no boneco por dois minutos. Se largar o controle, pare e conserte.

### Semana 3 — Bola de vírus + pendrive + sala de risco

Segunda arma (longe), troca de arma, pendrive de Processamento / Armazenamento no chão,
uma sala de risco com os três inimigos comuns (mesmo que feios), safezone mínima (cura +
porta). Aqui o loop Dead Cells existe pela primeira vez, ainda sem chefe de verdade.

### Semana 4 — Sistema de chefe + Balarrals + hub

Máquina de estados de chefe, telegrafia, barra, retry em menos de 2 s, hub com três portas.
**Balarrals** primeiro na produção (sprite espelhado = custo zero). Habilidade **Espelho**
mínima. As outras duas portas podem levar a um stub “em breve” até a semana seguinte.

### Semana 5 — LuanEvil e Renanligno

Ordem jogável nos três. Habilidades Caramelo e Eco. Pixel art dos dois conforme der.

### Semana 6 — Marlombólico

Trava o hub até os três estarem mortos; abre a porta dele. Interface mentindo.

### Semana 7 — Amandaconda

Duas fases, cena da porta, final do café. Única com tratamento completo.

### Semana 8 — Som, balanceamento e entrega

SFX de preparação por golpe de chefe, música, PyInstaller, teste em outra máquina.
**Corte se atrasar:** encolher salas de risco, não cortar chefe.

## A pixel art é o seu maior risco

Não é o código. Você programa em Python, e Pygame é direto. O gargalo é que cinco chefes, um
jogador e três inimigos animados são muitos quadros pra uma pessoa que também está programando
o jogo inteiro.

Cinco decisões que resolvem isso:

**Resolução interna baixa.** Trabalhe em 480×270 e escale para 1920×1080 (multiplicação
exata por 4, sem borrão). Jogador com ~48 px de altura, chefes entre 80 e 150. Nessa escala
um quadro leva minutos, não horas.

**Poucos quadros por animação.** Três a cinco, não doze. Pixel art boa é estalada, não suave.

**Nada de animação de morte.** Dissolva o sprite com partículas ou piscadas. Economiza o
conjunto de quadros mais caro de todos, nove vezes.

**Pacote gratuito como base pro jogador e pros inimigos comuns.** O itch.io tem uma
quantidade absurda de pixel art livre. Modifique em cima em vez de começar do zero.

**Faça à mão só os cinco chefes.** Eles são a homenagem e precisam ser reconhecíveis. Os
outros podem vir de biblioteca. Isso reduz o trabalho custom pra algo em torno de cem
quadros ao longo de oito semanas — dois ou três por dia.

E o truque que te dá produção alta de graça: **os cartões de entrada continuam sendo as
ilustrações que já existem** em `docs/arte/`. Jogo em pixel art com retrato ilustrado na
entrada do chefe é uma combinação clássica e parece caro.

## Riscos e reações

| Risco | Sinal de alerta | Reação |
|---|---|---|
| Combate sem graça | Semana 2, bater no boneco é chato | Pare tudo. Em 2D não tem arte pra disfarçar. |
| Pixel art engolindo o cronograma | Semana 4 e você está desenhando mais que programando | Corte quadros, use pacote gratuito, reduza resolução. |
| Cinco chefes é muito | Semana 6 e a Amandaconda não começou | Corte a travessia inteira, não um chefe. |
| Escrevendo motor demais | Você está fazendo sistema de partículas do zero | Só construa o que a tela precisa mostrar. |
| Números espalhados no código | Você caçou um valor por dez minutos | Pare e mova tudo pro arquivo de dados agora. |
| Perda de arquivos | — | Git desde o primeiro dia. |

## Próximos passos imediatos

1. Inicializar o repositório git com `.gitignore` de Python
2. Criar o ambiente virtual e instalar o Pygame
3. Montar o esqueleto do projeto: laço com passo fixo, resolução interna escalada, um
   retângulo que anda
4. Criar `data/balance.json` vazio já na primeira linha de código
