# AMANDACONDA — Documento de Design

**Versão:** 5.2 (narrativa elaborada; campus aberto; habilidade de chefe; Unreal 3D)
**Gênero:** Action soulslike em terceira pessoa — campus semiaberto, exploração, chefes
opcionais na ordem que você aguentar, progressão por pendrive / Bytes / habilidade
**Equipe:** 1 pessoa
**Duração:** 1,5 a 3 horas de conteúdo (mais com exploração e mortes)
**Engine da entrega:** Godot 4.7 (Forward Plus + Jolt), terceira pessoa.
Unreal e Pygame ficam como referência / arquivo morto — não são o runtime oficial.

Números de combate e balanceamento ficam em [NUMEROS.md](NUMEROS.md) e
`data/balance.json` (unidades em metros no Godot).

---

## 1. O que é

Uma faculdade à noite. O campus está **aberto**: você explora corredores, atalhos e
safezones, enfrenta inimigos comuns, acha pendrives — e **decide** quando encarar cada
chefe-base. Não há menu de “escolha a porta na ordem certa”. Há liberdade. E punição.

Os chefes-base (LuanEvil, Renanligno, Balarrals) estão no mapa desde o começo. Ir cedo em
área difícil é permitido — e costuma matar você. Ir preparado (pendrives, Bytes, habilidade
roubada) é a rota “inteligente”. Estilo *Elden Ring*: o jogo não segura sua mão.

Derrote os chefes-base e o caminho pros **bosses finais** abre (Marlombólico → Amandaconda).
Cada chefe-base morto ainda **entrega uma habilidade** — você “rouba” o defeito / a marca
daquele amigo e usa como ferramenta (estilo Great Rune / remembrance, não menu Mega Man).
No fim, ela está encostada na porta, fumando, com um café na mão. Esperando.

**Referências estruturais:**

| Jogo | O que pegamos |
|---|---|
| *Elden Ring* | Campus semiaberto; soft locks; “pode ir, mas é difícil”; Sites of Grace ≈ safezones; exploração recompensa. |
| *Dead Cells* | Pendrive = pergaminho; Bytes = cells; Patches ≈ mutações; drop e power-up dentro da run. |
| *Dark Souls / Salt and Sanctuary* | Combate soulslike: vigor, rolamento, telegrafia, culpa no jogador, atalho, morte que ensina. |

Não é roguelike de runs infinitas. O campus é fixo e conectado. A escolha grande é **para
onde ir agora** e **se você está pronto** — não um menu de três portas em sequência.

### A homenagem

O jogo é uma homenagem a um grupo de amigos. Os quatro minichefes são eles, transformados em
versões monstruosas da própria personalidade. A Amandaconda é a quinta e é o chefe final.

Os quatro são a comédia. Ela é a comédia *e* o mistério — e o único que o jogo trata com
respeito de verdade.

### Narrativa — por que você está ali

A faculdade **não fechou**. Ela *suspendeu*.

De dia é matrícula, RU, laboratório, fila do Wi-Fi. De noite o campus vira outra coisa:
luzes de emergência, impressoras que spitam erro em loop, o bandejão em greve eterna, o lab
com a bolinha colorida girando num Mac que ninguém desligou. Corredores que conectam salas
que de dia não se encostam. Servidores que “já iam ser desativados em 2014”.

**Você** não tem nome na ficha. Não é o escolhido. É quem ficou — ou quem voltou — ou quem
abriu o chamado errado às 23:47. A interface fala com você como um terminal meio morto,
meio zoeira de plantão:

`SESSION_STUCK.`  
`RECOVER DATA.`  
`FIND EXIT.`

O objetivo oficial é achar a **saída**. O problema é a pichação ao lado da placa: *“não
existe saída”*. Explorar não é turismo: é fechar tickets, recuperar Bytes (dados), achar
atalhos, e descobrir o que o campus está **segurando** pra não te deixar ir embora.

Os quatro amigos viraram **lendas de corredor** — processos que não morreram. Personalidades
engolidas pela noite e regurgitadas como chefes. Matá-los não é assassinato na história: é
fechar o chamado deles, roubar o que sobrou de útil (a habilidade), e provar que você aguenta
o plantão.

Quem segura a porta no fim não é segurança. É **ela**.

### O enigma da Amandaconda

Ninguém no campus sabe a idade dela. As teorias são todas ruins e todas verdadeiras o
suficiente:

- Dizem que ela estava na **arca de Noé** — “já viu o dilúvio e o Windows XP”.
- Dizem que ela instalou a primeira rede da faculdade com cabo coaxial e paciência.
- Dizem que ela **bate em criança e tranca no lab** (piada interna do grupo — vira lenda
  do campus: calouro some, volta no dia seguinte com trauma e um crachá de “estagiário”).
- Ela fala como **tiozão de informática das antigas**: “já tentou desligar e ligar de
  novo?”, “isso aí é cache”, “na minha época a gente compilava e rezava”, senha no Post-it,
  café que parece betume, cigarro no intervalo entre apocalipses.

O mistério de verdade não é a idade. É o papel dela.

A Amandaconda **não guarda a saída pra te impedir**. Ela *é* o teste da saída. O campus à
noite é o limbo do plantão eterno — e ela é root. Você só sai se ela decidir que você
aguendeu. Por isso a luta começa com ela de boa no cigarro: pra ela, sua jornada inteira
foi o tempo de um café.

Ela é sincera no humor e cruel na cobrança. Engraçada o bastante pra você rir. Antiga o
bastante pra você não saber se está brincando com uma amiga ou com um mito.

## 2. Pilares de design

1. **Todo chefe ensina uma coisa que nenhum outro ensina.** Se dois chefes cobram a mesma
   habilidade, um dos dois está errado.
2. **Todo dano tomado é culpa do jogador.** Ataques telegrafados, sem aleatoriedade, sempre
   com janela de punição depois do combo.
3. **O defeito de cada amigo é a mecânica do chefe dele.** É essa a piada e é esse o design.
4. **Os minichefes são obstáculos. Ela é um evento.** Todo o orçamento de produção extra vai
   pra Amandaconda.
5. **Matar chefe = roubar a característica dele.** A recompensa não é loot genérico: é a
   personalidade daquele amigo virando habilidade jogável. Pendrive e habilidade existem,
   mas nunca substituem aprender o padrão. Se o upgrade matar a necessidade de esquivar,
   está errado.

## 3. O jogador

**Você.** Sem nome de ficha, sem cutscene de origem, sem personagem fictício entre você e o
jogo. A interface fala com você diretamente. A história mora no **campus** e nela — não
num diário do protagonista.

Isso não é preguiça narrativa — é uma decisão que o Marlombólico depende. Quando ele inverte
os controles e mente na barra de vida, ele está mexendo com **você**, não com um avatar.

**Cura:** lata de energético. Quantidade limitada por tentativa, e beber leva tempo suficiente
pra ser punido. A safezone recarrega.

**Visual:** o sprite base é **desarmado**. Arma só aparece depois da escolha no início (e
só a escolhida). Nada nas costas “por padrão”.

### Escolha de escola (no início)

Depois do tutorial / abertura, uma tela curta: **você pega uma coisa no laboratório**.

| Escola | Arma | Estilo |
|---|---|---|
| **Físico** | Teclado | Perto. Combo, alcance curto, dano estável. |
| **Especial** | Poder (bola de vírus) | Longe. Projétil, bounce, DPS por acerto menor. |

Na fase 1 você usa **só a escola escolhida** a run inteira. Trocar arma some do moveset.
Mais pra frente (meta esticada / fase 2) desbloqueia o segundo slot — aí vira Dead Cells de
verdade (duas mãos). Até lá, o escopo cabe.

Isso também resolve a PixelLab: gera o boneco **sem arma**; o teclado/vírus é overlay ou
folha separada no ataque.

### Moveset base

| Ação | Detalhe |
|---|---|
| **Ataque leve** | Depende da escola (combo no teclado / tiro no poder). |
| **Ataque pesado** | Carregável na escola escolhida. |
| **Esquiva** | Rolamento com invencibilidade. Única defesa. |
| **Pulo** | Espaço / ✕ (X no PlayStation, A no Xbox). |
| **Vigor** | Correr, rolar e atacar consomem. Regenera parado. |
| **Cura** | Limitada por tentativa, lenta, punível. |
| **Habilidade de chefe** | Uma por vez (ver §10). |

Não existe escudo, aparo, nem troca de arma no meio da run (até o segundo slot existir).

### Controles e inputs (teclado + joystick)

Unreal Enhanced Input — **mesmo moveset** em teclado+mouse e gamepad.

| Ação | Teclado + mouse | Joystick (Xbox / PlayStation) |
|---|---|---|
| Mover | WASD | Analógico esquerdo |
| Olhar / câmera | Mouse | Analógico direito |
| Correr (vigor) | Shift | L3 ou LT |
| **Pular** | **Espaço** | **A / ✕ (X)** |
| Ataque leve | Botão esquerdo | RB / R1 |
| Ataque pesado | Botão direito (segurar) | RT / R2 |
| Rolamento | Ctrl / C | B / ○ |
| Lock-on | Botão do meio / Tab | R3 |
| Cura | Q | D-pad ↓ |
| Habilidade de chefe | E | X / □ |
| Interagir | F | Y / △ |
| Pausa | Esc | Menu / Options |

Ajuda no jogo no formato curto: `Espaço / X — pular`.

## 4. Os inimigos comuns

Não são pessoas. São **a infraestrutura da faculdade**, viva e hostil. Além de ser a piada
que qualquer estudante entende, é uma decisão de escopo importante: objeto não precisa de
esqueleto, nem de rig humanoide, nem de ciclo de caminhada.

Os três se combinam pra formar encontros variados sem que nada novo precise ser criado.

### Chatana

Faz um barulho insuportável. **Não é uma ameaça — ela piora as outras ameaças.**

O ataque dela é sonoro e atinge sua percepção: embaralha a tela, abafa o áudio dos outros
inimigos, tira sua referência auditiva. Sozinha é fácil e irritante. Acompanhada, ela te cega
enquanto os outros te matam.

**Ensina:** priorização de alvo. Mata a Chatana primeiro. Sempre.

### Portara

Muito lenta. Muito resistente. **Não pode ser atordoada.**

É um muro ambulante que bloqueia corredores. O golpe dela é uma investida lentíssima e
telegrafadíssima que esmaga se acertar. Matar a Portara é possível mas custa caro em tempo e
vigor — geralmente a resposta certa é simplesmente passar por ela.

**Ensina:** nem todo inimigo se resolve batendo.

### Net

Antena parabólica. Fica na parede ou no teto, gira, e ataca de longe.

Ela te **marca** com o sinal. Enquanto marcado, você toma dano contínuo e os outros inimigos
sabem exatamente onde você está. Não precisa andar, o que a torna o inimigo mais barato do
jogo.

**Ensina:** usar cobertura e fechar distância.

## 5. Os quatro minichefes

Cada um tem no máximo **três ataques e uma fase**. Eles são obstáculos, não eventos. As arenas
deles são os próprios espaços da faculdade, não salas dedicadas.

### 1. LuanEvil — o refeitório

Tanque puro. Enorme, lenta, imparável. Nada a move do lugar.

**O gancho é o chão.** Conforme a luta avança, a arena vai ficando coberta de **pipoca doce
grudenta**. Você começa com espaço de sobra e termina sem lugar pra rolar. A luta não é sobre
o dano dela, é sobre o espaço que você está perdendo.

Boa primeira chefe: perdoa erro, mas ensina uma lição dura.

**A arena é o bandejão em greve.** Mesas viradas, faixas penduradas nas vigas, avental do RU,
armadura improvisada de bandeja de metal. Mais específico e mais engraçado que um refeitório
genérico.

**O headphone.** Ela começa a luta com o fone pendurado no pescoço, e a trilha da luta toca
**abafada e fininha, como som vazando do fone de outra pessoa**. Na metade da vida, ela
coloca o fone. A música estoura em volume cheio, ela acelera, e o caramelo passa a se
espalhar mais rápido.

Não é uma segunda fase — não tem golpe novo. É um único momento de escalada, feito com um
filtro de áudio e uma animação. Custa quase nada e é o que o jogador vai contar pros amigos.

**Ela sorri o tempo inteiro.** Não é raiva, é alegria genuína de te ver. Uma parede que você
não consegue mover e que está feliz com a sua presença é muito mais perturbadora que
qualquer careta — e é a tradução honesta de "gente boa".

**Ensina:** gerenciamento de espaço.
**Recompensa:** habilidade **Caramelo** — a “gente boa” que cola e segura o espaço vira a
sua poça que freia inimigos.
**Custo de produção:** baixo. São decals no chão e um volume que reduz velocidade.

### 2. Renanligno — o laboratório de informática

Os ataques dele saem **fora do tempo**. Ele prepara, você rola por reflexo, e o golpe chega
depois que você já rolou. Ele quebra deliberadamente o ritmo que você aprendeu na LuanEvil.

**Como isso permanece justo:** um chefe que ataca fora do compasso vira injusto rapidamente.
A solução são os **fantasmas atrasados** que ele arrasta atrás do corpo. O fantasma executa o
golpe primeiro; o corpo real repete meio segundo depois. O jogador tem uma leitura perfeita, e
o desafio deixa de ser adivinhar — passa a ser **ignorar o tempo do fantasma e esperar o
corpo**. Difícil e honesto ao mesmo tempo.

Ele é o chefe de maior dano do jogo, e o corpo dele precisa comunicar isso. Não é um espectro
esquelético: é alguém forte que bate como um caminhão e simplesmente chega tarde.

O MacBook dele **trava** no meio da luta, com a bolinha colorida girando: ele fica parado e
indefeso por alguns segundos. Mas quando destrava, vem tudo que ficou acumulado de uma vez.

**Ensina:** paciência. Não rolar por reflexo.
**Recompensa:** habilidade **Eco** — o atraso deliberado dele vira o seu golpe fantasma
que acerta um tempo depois.
**Custo de produção:** baixo. Os fantasmas são cópias translúcidas do mesmo esqueleto tocando
a mesma animação com atraso — reaproveitam tudo e não custam animação nova.

### 3. Balarrals — o pátio interno

O espelho. **Ele usa exatamente o seu moveset** — mesmas animações, mesmos ataques, mesma
esquiva, mesmo vigor. Um duelo limpo contra você mesmo, num pátio aberto sem cenário
atrapalhando.

**A mão trocada.** Ele segura a cadeira na mão contrária à sua. Tudo nele é idêntico menos o
lado, porque espelho é isso. A maioria dos jogadores não vai registrar conscientemente — só
vai sentir que tem algo errado e não vai saber dizer o quê.

Ele provoca sem parar, e atacar com raiva no meio da provocação é punido. **A cara dele já é
a mecânica:** o sorriso torto e debochado existe pra você querer bater, e querer bater é
exatamente como ele te mata.

**Ensina:** disciplina. E é o teste honesto de tudo que você aprendeu até aqui.
**Recompensa:** habilidade **Espelho** — o duelo contra você mesmo vira o contra-golpe
ao rolar *através* do ataque inimigo.
**Custo de produção:** o mais baixo do projeto inteiro, porque reaproveita cem por cento do
que já foi feito pro jogador. **Por isso ele deve ser o primeiro a ser construído**, mesmo
sendo o terceiro a ser jogado.

### 4. Marlombólico — a sala dos servidores

O penúltimo, e o mais difícil dos quatro. Ele **hackeia o jogo**.

Inverte seus controles por alguns segundos. Esconde sua barra de vida. Mostra uma barra de
vida falsa, dele, que não corresponde à real. Faz aparecer um clone. Mexe na interface, no
menu, nas coisas que o jogador acha que são sagradas.

É o único chefe que quebra a quarta parede, e funciona precisamente porque o jogador é você
mesmo, sem personagem fictício no meio.

**O corpo dele desmente a dificuldade.** Não é um monstro musculoso — é magro, alto, de boné
pra trás e chinelo. **Ele luta com uma mão no bolso.** O chefe mais difícil dos quatro não
estar nem se esforçando intimida mais que qualquer músculo, e reforça o que ele é: quem dobra
as regras não precisa de força.

**Ensina:** manter a calma quando o jogo mente.
**Custo de produção:** médio-baixo. Quase tudo é interface e um duplicado do modelo.

### Progressão das lições

Espaço, ritmo, duelo puro, caos. Nenhuma lição se repete, e a dificuldade sobe de forma
limpa até a porta.

## 6. A Amandaconda

Humanoide com traços de serpente, o tempo todo. Alta, elegante, escamas, olhos de cobra, e
uma cauda longa que é a arma principal. Nunca desajeitada — tudo que ela faz é rápido e
fluido.

Ela recebe tratamento de chefe completo: **duas fases e arena dedicada**. É a única.

### A porta

Você atravessou a faculdade inteira, apanhou, morreu dezenas de vezes, fechou os tickets
dos quatro, e chega na saída.

Ela está **encostada na porta, fumando, com um café na mão**. Não em pose de combate. Não
numa arena épica. De boa, no intervalo — como quem já viu mil plantões iguais.

Isso comunica o abismo entre vocês melhor do que qualquer cutscene: tudo que você acabou de
passar, pra ela, foi o tempo de um cigarro.

Ela te olha. Fala uma coisa de tiozão — algo tipo *“demorou, hein? Achei que ia ficar
preso no lab pra sempre”* ou *“na minha época a gente saía sem save”*. Apaga o cigarro e
**apoia a xícara com cuidado num parapeito**. Aí a luta começa.

**A xícara fica ali a luta inteira**, visível no canto da arena. É um adereço estático — custa
nada — e é o que amarra o final.

**A pichação.** Ao lado da placa oficial de SAÍDA, alguém escreveu na parede: *"não existe
saída"*. Fica no enquadramento durante a luta inteira. (Mentira meia-verdade: saída existe.
É ela.)

### Fase 1 — até 50% de vida

Telegrafia generosa, combos curtos, ensina os padrões.

1. **Investida** — avança e dá uma garrada. Punível se você esquivar pro lado.
2. **Combo de garras** — três golpes em ritmo constante.
3. **Chicotada de cauda** — horizontal e baixa. Rolar pro lado não salva; tem que pular ou
   rolar pra trás.
4. **Bote** — o agarrão. Maior dano da fase, e o mais telegrafado.
5. **Cuspe** — projétil de longa distância, pra que esperar longe nunca seja seguro.

### Fase 2 — de 50% até o fim

Sem transformação. Muda a intensidade: a música vira, a iluminação muda, os olhos acendem e a
cauda entra em jogo pra valer. Mantém tudo da fase 1 e adiciona:

6. **Giro de cauda** — 360 graus, duas voltas. A segunda vem mais rápida que a primeira, e é
   aí que o jogador morre.
7. **Constrição** — ela se enrola nas colunas e transforma parte do chão em zona de perigo,
   forçando reposicionamento.
8. **Combo estendido** — cinco golpes com uma pausa proposital no meio. Quem ataca na pausa
   toma os dois últimos.

### Regras de justiça

- Todo ataque tem pose de preparação visível e distinta.
- Nenhum ataque muda de direção depois de começar.
- Todo combo tem janela real de punição no fim.
- Distância nunca é segurança total, proximidade nunca é morte garantida.

## 7. O final

Você vence. **Ela não morre.**

Ela se levanta, se ajeita, pega a xícara que ficou no parapeito a luta inteira — e te oferece.
Talvez diga algo seco e afetuoso: *“toma. Agora você é do plantão.”* Ou só ergue a sobrancelha,
como quem já sabia.

Corte. Créditos com os cinco — os amigos monstro e ela, humana demais pra ser só chefão.

Você não derrotou a Amandaconda. Você foi **aceito**. A sessão fecha. A saída, enfim, existe —
porque ela deixou.

## 8. O mapa — campus aberto (soulslike)

### Filosofia (Elden Ring, escala faculdade)

O jogador **não é guiado por um menu de chefes**. Ele anda pelo campus, vê um caminho
perigoso, decide entrar. Soft locks existem (portões, cartões, elevadores) mas a maior parte
das arenas-base está **alcançável cedo** — o que impede não é a tranca, é a dificuldade.

```
                    [ Safezone / “grace” ]
                     /        |        \
           corredor      corredor      corredor
           (risco)       (risco)       (risco)
              |             |             |
         LuanEvil      Renanligno     Balarrals
              \             |             /
               ---- (3 chefes-base) ----
                          |
                   Marlombólico (final 1)
                          |
                   Amandaconda (final 2)
```

### Soft locks (o que “libera”)

| Condição | O que abre |
|---|---|
| Tutorial concluído | Campus explorável; 3 arenas-base acessíveis |
| **1** chefe-base morto | Atalhos / cartão parcial; habilidade daquele chefe |
| **3** chefes-base mortos | Zona dos **servidores** → **Marlombólico** |
| Marlombólico morto | Corredor da **saída** → cena da porta → **Amandaconda** |

Regra de honestidade Elden Ring: se o jogador achar um caminho “cedo demais”, o jogo **deixa**.
Ele só não equilibra a área pra baixo. Morrer é o feedback.

### Zonas do campus

| Zona | Chefe / conteúdo | Tom de dificuldade |
|---|---|---|
| Recepção / tutorial | Nenhum | Seguro — ensina andar, atacar, rolar |
| Hall / safezone central | Servidor de backup, banco de habilidade | Sem combate |
| Bandejão + anexos | **LuanEvil** | Médio — espaço e caramelo |
| Lab de informática | **Renanligno** | Médio-alto — ritmo / paciência |
| Pátio interno | **Balarrals** | Alto se você for sem moveset maduro — espelho |
| Corredores “sujos” | Só comuns + loot | Variável; atalhos entre zonas |
| Servidores | **Marlombólico** | Final 1 — trancado até 3 bases |
| Porta de saída | **Amandaconda** | Final 2 — trancado até Marlon |

### Loop local (ainda existe)

Dentro de cada braço do campus o feeling continua:

```
[ Exploração / risco ]  →  [ Safezone próxima ]  →  [ Arena do chefe ]
   inimigos + loot           cura + Bytes              luta
```

A diferença: depois da luta você **não volta pra um menu de portas** — você volta pro campus
com atalho novo, habilidade nova, e liberdade pra ir onde quiser.

### Safezone (“Site of Grace” do campus)

Sem inimigos. Sempre:

- Recarrega cura; ponto de respawn da região
- Bancada pra **equipar habilidade de chefe** (uma por vez)
- **Servidor de backup** — gastar Bytes em Patches / Drivers (no hub ou em safezones-chave)
- Mostra escola ativa, níveis Físico / Especial e Bytes (`KB`)
- Atalhos que você já abriu aparecem no “mapa mental” (placas / setas / UI mínima)

Morrer no chefe devolve na **safezone mais próxima da arena** (ou fogão da porta), não no
começo do jogo.

### Esqueleto de progressão (não linear)

| Momento | O que o jogador pode fazer |
|---|---|
| Pós-tutorial | Explorar qualquer braço-base; morrer muito é esperado |
| 0–2 chefes | Farm de Bytes/pendrives; aprender um moveset; abrir atalhos |
| 3 chefes-base | Servidores liberam; Marlon vira o foco |
| Pós-Marlon | Porta da saída; Amandaconda |
| Opcional | Voltar a zonas, pegar loot perdido, trocar habilidade |

## 9. Morte e nova tentativa

**Requisito, não polimento:**

| Onde morreu | Volta |
|---|---|
| Sala de risco | Início daquela sala (inimigos e pendrives da sala resetam) |
| Chefe | Porta da arena, menos de 2 s, sem cutscene de novo |

Pendrives **já pegos e aplicados** na run atual não somem ao morrer no chefe. Morrer na sala
de risco antes de sair dela perde só o que ainda não foi pego naquela sala.

## 10. Progressão

Duas camadas: **escola** (escolhida uma vez) e **pendrive** (várias vezes). Sem inventário,
sem árvore de talento, sem loja.

### O que o Dead Cells faz (e o que a gente copia)

No Dead Cells existem três cores — Brutality, Tactics, Survival. Armas “escalam” com uma
cor. Cada pergaminho sobe **uma** cor e dá:

1. **+15% de dano cumulativo** nas armas daquela cor (`base × 1,15^(nível−1)`)
2. **Um pouco de vida**, com retorno decrescente; Survival dá mais vida, Tactics dá menos

Pergaminhos de **duas opções** ( Assassin / Minotaur / Guardian ) forçam trade-off: você
escolhe entre duas cores. A estratégia boa é **commitar numa cor** — splitar dano enfraquece
as duas. Cor off-color vira, na prática, “pegar vida”.

A gente não tem três cores nem catálogo de 80 armas. Tem **duas escolas** e **uma arma
ativa**. O pendrive é o pergaminho de duas opções.

### Pendrive (sempre oferece escolha)

No chão da sala de risco. Ao pegar, **pausa curta** e duas opções (como o scroll dual do
Dead Cells). Não são dois itens diferentes no chão — é um pendrive só, com fork:

| Opção | Cor na UI | Dano | Vida |
|---|---|---|---|
| **Físico** | Âmbar | +8% no dano da escola Físico (cumulativo) | +18 vida máx. |
| **Especial** | Verde neon | +15% no dano da escola Especial (cumulativo) | +8 vida máx. |

Números em `balance.json` — estes são o ponto de partida.

**Como escala o dano (copiado do Dead Cells, simplificado):**

`dano = base × (1 + taxa)^nível_da_escola`

- Escolheu teclado e só pega Físico → fica tanky e o teclado escala.
- Escolheu teclado e pega Especial → ganha pouca vida e **quase não sobe o dano** (a %
  Especial não aplica no teclado). É o “off-color” do Dead Cells: válido se estiver
  morrendo, ruim se quiser matar mais rápido.
- Mesma lógica invertida pro poder.

Quando existir o **segundo slot** (depois), pendrives off-color passam a valer de verdade
no dano da segunda arma. Até lá, a escolha é: **commitar na sua escola** ou **comprar vida**.

Quantidade: ~1–2 pendrives por sala de risco. Ao aplicar, cura a vida ganha no aumento de
máximo (senão o item “não parece ter feito nada”).

**Regra de honestidade:** o último chefe ainda exige esquivar. Pendrive acelera a run, não
trivializa.

### Habilidade de chefe (a marca do amigo)

Ao matar um chefe-base, você **roubá a característica dele** e vira habilidade jogável.
É a parte Mega Man / Great Rune que **fica**: não há ordem obrigatória, mas há **motivo
pra matar** cada um — o campus fica mais fácil *e* você carrega um pedaço daquele amigo.

Equipa **uma** por vez na safezone. As outras ficam desbloqueadas pra trocar entre lutas.
Incentiva matar os três antes dos finais sem forçar menu de portas.

| Chefe | Personalidade / defeito | Habilidade (rascunho — ajustar na fase 1) |
|---|---|---|
| **LuanEvil** | Gente boa, tanque, cola no espaço | **Caramelo** — poça que freia inimigo / chefe por um instante |
| **Renanligno** | Fora do tempo, paciência forçada | **Eco** — golpe fantasma que acerta depois na mesma pose |
| **Balarrals** | Espelho, provocação, disciplina | **Espelho** — contra-golpe curto se rolar *através* do ataque |

Marlombólico **não** entrega habilidade jogável (ele bagunça a interface; copiar isso vira
meta-joke ruim e caro). A recompensa dele é abrir o caminho pra ela.

Amandaconda não entrega habilidade — entrega o final.

### Bytes / KB (o “cell” do campus)

Moeda do mundo de TI — **não** é coin, chip nem gem. Você está recuperando **dados**.

| | |
|---|---|
| Nome interno | `bytes` |
| HUD | `12 KB`, `1.5 MB` quando passar de 1024 |
| Drop | Inimigos comuns (Chatana / Portara / Net) |
| Chefes | **não** dropam Bytes (recompensa = habilidade / progresso) |
| Onde gasta | Hub → **Servidor de backup** (tela tipo terminal) |

**Não compete com o pendrive:**

| Sistema | Função |
|---|---|
| **Pendrive** | Poder **dentro** da sala de risco (Físico / Especial) |
| **Bytes** | Progressão / desbloqueio no hub |
| **Habilidade de chefe** | Ferramenta tática entre lutas |

Drops-alvo (ponto de partida — `balance.json`):

| Inimigo | Bytes |
|---|---|
| Chatana | 24–40 |
| Portara | 48–72 |
| Net | 32–56 |

### Patches (passivas da playthrough)

Equivalente às mutações do Dead Cells. Comprados/ativados no Servidor de backup com Bytes.
Valem **até o fim da playthrough** (morrer no chefe não apaga; recomeçar do menu zera).

- Até **3 slots** de Patch equipados
- Pool começa pequena; gastar Bytes **desbloqueia** novos Patches no catálogo (meta leve)
- Exemplos de tom (números depois): `hotfix_vigor`, `daemon_cura_safe`, `macro_rolamento`

UI: cartão terminal (`PATCH · hotfix_vigor`), não ícone de RPG.

### Drivers (desbloqueios permanentes)

Equivalente à forja / desbloqueio de arma do Dead Cells. Salvam em arquivo local.

- Gastam Bytes no mesmo Servidor de backup
- Liberam conteúdo pra **próximas** playthroughs (e o resto desta, se fizer sentido)
- Exemplos: variação de escola, segundo slot (meta esticada), cosmético de HUD, Patch raro no pool

**Regra de escopo fase 1:** Servidor de backup + Bytes dropando + **3–5 Patches** + **2–3 Drivers**
bastam. Catálogo enorme fica pra depois.

## 11. Identidade visual

Arte de conceito em [`docs/arte/`](arte/).

**Regra geral:** fundo quase preto, uma fonte de luz colorida forte, e objetos completamente
banais tratados com seriedade absoluta. Cadeira de plástico, balde de pipoca, crachá, MacBook
— tudo iluminado como relíquia. O contraste entre o mundano e o épico *é* o estilo do jogo.

### Uma cor por chefe

Cada chefe tem uma cor própria, usada na iluminação da arena, na barra de vida e nos efeitos
dos golpes. É assim que o jogador vai lembrar de cada luta, e não custa quase nada.

| Chefe | Cor |
|---|---|
| LuanEvil | Âmbar dourado de caramelo |
| Renanligno | Azul frio |
| Balarrals | Prata de luar, quase sem cor |
| Marlombólico | Verde neon de terminal |
| Amandaconda | Verde-petróleo com âmbar |

### Cartão de entrada de chefe

Cada chefe entra com um retrato em close na cor dele, com o nome sobreposto. A sacada é que
**cada cartão imita uma interface diferente, tirada do tema do próprio chefe**:

| Chefe | A interface do cartão |
|---|---|
| LuanEvil | Cardápio do RU, quadro de aviso do bandejão |
| Renanligno | Caixa de diálogo de erro do sistema, roda de carregamento |
| Balarrals | Formulário de matrícula, ou o cartão do jogador espelhado |
| Marlombólico | Terminal de linha de comando, texto verde rolando |
| Amandaconda | Crachá funcional, ficha do RH |

É tudo interface 2D, então custa quase nada, e transforma cinco telas repetidas em cinco
piadas diferentes.

### A Amandaconda

Mantê-la **majoritariamente humana**. As escamas invadem, não cobrem: um lado do rosto, as
têmporas, o pescoço, os antebraços. Meia humana é mais perturbador — e mais barato — do que
monstro inteiro.

Traços obrigatórios, porque são o que fazem dela **ela** e não uma mulher-cobra qualquer:

- Óculos redondos com corrente de contas — a corrente lê como uma cobrinha enrolada no pescoço
- Batom vermelho forte
- Cabelo ondulado claro, na altura do ombro
- Tatuagem no antebraço
- Crachá de TI no peito
- Expressão de quem não está nem aí

### O corpo dela — decisão pendente

A arte de conceito a desenhou como lâmia, com cauda no lugar das pernas. Isso exige modelagem
e rigging próprios, o que contraria diretamente a restrição de não modelar nada e não cabe no
cronograma.

**Opção recomendada:** bípede com uma cauda longa presa atrás, animada por física ou spline.
Mantém todos os ataques de cauda, funciona com MetaHuman e com todo o acervo do Mixamo. A
lâmia fica só na arte promocional, na tela de título e na cena da porta antes da luta começar.

### Pipeline de semelhança

MetaHuman. O caminho mais preciso é escanear o rosto da pessoa real com um aplicativo de
celular (Polycam ou KIRI Engine, ambos gratuitos) e importar via Mesh to MetaHuman. Sem scan,
dá pra esculpir manualmente no MetaHuman Creator usando a arte de conceito como referência.

## 12. Fora de escopo

Lista pra reler na semana 8, quando bater a tentação.

- Seleção de personagem (um só: você)
- Roguelike / runs aleatórias / procedural
- Mundo aberto, mapa além do hub + salas do loop
- Qualquer chefe além dos cinco
- Qualquer inimigo comum além dos três
- Arsenal com muitas armas; loja com catálogo
- Terceira cor de stat (só Físico e Especial)
- Inventário / crafting genérico (Patches/Drivers no Servidor de backup **estão** no escopo, enxutos)
- Segundo slot de arma (Driver / meta esticada — não na entrega mínima da fase 1)
- Multiplayer ou co-op
- Cutscenes longas, animação facial, lipsync
- Escudo e aparo (metas esticadas)
- Qualquer linha de C++
- Modelagem 3D e animação próprias — tudo de biblioteca gratuita
