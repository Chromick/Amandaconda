# AMANDACONDA — Documento de Design

**Versão:** 3.0 (boss rush com travessia, duas fases de produção)
**Gênero:** Soulslike reduzido — quatro minichefes, um chefe final
**Equipe:** 1 pessoa
**Duração:** 45 a 60 minutos de conteúdo, 2 a 4 horas de jogo real

Este documento é **independente de engine**. Ele descreve o jogo; como construí-lo está nos
dois roteiros de produção.

| | Fase 1 | Fase 2 |
|---|---|---|
| Ferramenta | Pygame, Python | Unreal Engine 5, só Blueprint |
| Dimensão | 2D, vista lateral | 3D, terceira pessoa |
| Arte | Pixel art | Assets de biblioteca gratuita |
| Prazo | ~8 semanas | ~8 semanas |
| Plano | [ROADMAP-pygame.md](ROADMAP-pygame.md) | [ROADMAP-unreal.md](ROADMAP-unreal.md) |

A fase 1 é o **protótipo** da fase 2. Os valores de balanceamento descobertos lá atravessam
inteiros, e estão em [NUMEROS.md](NUMEROS.md).

---

## 1. O que é

Um percurso pela faculdade, à noite, interrompido por cinco lutas.

Você atravessa trechos curtos cheios de inimigos comuns, enfrenta quatro minichefes, e no fim
chega na saída. A Amandaconda está encostada na porta, fumando, com um café na mão. Esperando.

Não tem mundo aberto, não tem exploração, não tem loot, não tem level up. É um corredor com
cinco lutas, e a graça está em ficar bom nelas.

**Referência estrutural:** *Furi* — lutas de chefe ligadas por travessias curtas. É exatamente
esse formato, e é um jogo que uma equipe muito pequena conseguiu fazer.

### A homenagem

O jogo é uma homenagem a um grupo de amigos. Os quatro minichefes são eles, transformados em
versões monstruosas da própria personalidade. A Amandaconda é a quinta e é o chefe final.

Os quatro são a comédia. Ela não é.

## 2. Pilares de design

1. **Todo chefe ensina uma coisa que nenhum outro ensina.** Se dois chefes cobram a mesma
   habilidade, um dos dois está errado.
2. **Todo dano tomado é culpa do jogador.** Ataques telegrafados, sem aleatoriedade, sempre
   com janela de punição depois do combo.
3. **O defeito de cada amigo é a mecânica do chefe dele.** É essa a piada e é esse o design.
4. **Os minichefes são obstáculos. Ela é um evento.** Todo o orçamento de produção extra vai
   pra Amandaconda.

## 3. O jogador

**Você.** Sem nome, sem história, sem personagem fictício entre você e o jogo. A interface
fala com você diretamente.

Isso não é preguiça narrativa — é uma decisão que o Marlombólico depende. Quando ele inverte
os controles e mente na barra de vida, ele está mexendo com **você**, não com um avatar.

**Arma:** improvisada, achada na própria faculdade. A proposta é uma cadeira universitária de
plástico, daquelas com braço-mesa. Mundana e ridícula de propósito — o contraste com a
Amandaconda é parte da graça.

**Cura:** lata de energético. Quantidade limitada por tentativa, e beber leva tempo suficiente
pra ser punido.

### Moveset

Só existe um personagem jogável, então todo o polimento vai pra este moveset.

| Ação | Detalhe |
|---|---|
| **Ataque leve** | Encadeável em combo de 3. Rápido, dano baixo. |
| **Ataque pesado** | Carregável. Lento, dano alto, te deixa exposto. |
| **Esquiva** | Rolamento com janela de invencibilidade. É a única defesa do jogo. |
| **Vigor** | Correr, rolar e atacar consomem. Regenera parado. É o freio. |
| **Cura** | Limitada por tentativa, lenta, punível. |
| **Lock-on** | Trava a câmera no alvo. Ligado por padrão em luta. |

Não existe escudo e não existe aparo. A esquiva é a resposta pra tudo, e isso mantém o
combate legível e o escopo sob controle. *(Aparo fica como meta esticada, se sobrar tempo.)*

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

Você atravessou a faculdade inteira, apanhou, morreu dezenas de vezes, e chega na saída.

Ela está **encostada na porta, fumando, com um café na mão**. Não em pose de combate. Não
numa arena épica. De boa, no intervalo.

Isso comunica o abismo entre vocês melhor do que qualquer cutscene: tudo que você acabou de
passar, pra ela, foi o tempo de um cigarro.

Ela te olha. Fala uma coisa casual. Apaga o cigarro e **apoia a xícara com cuidado num
parapeito**. Aí a luta começa.

**A xícara fica ali a luta inteira**, visível no canto da arena. É um adereço estático — custa
nada — e é o que amarra o final.

**A pichação.** Ao lado da placa oficial de SAÍDA, alguém escreveu na parede: *"não existe
saída"*. Fica no enquadramento durante a luta inteira.

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

Corte. Créditos com os cinco.

Você não derrotou a Amandaconda. Você foi aceito.

## 8. O mapa

Um percurso linear pela faculdade à noite. Nove espaços, sem ramificação, sem se perder.

| # | Espaço | O que acontece |
|---|---|---|
| 1 | Recepção | Tutorial silencioso. Sem inimigos. Você testa os controles sozinho. |
| 2 | Corredor do bloco A | Primeiro contato com a Chatana. |
| 3 | **Refeitório** | **LuanEvil** |
| 4 | Escadaria e biblioteca | Portara bloqueando, Net na parede. |
| 5 | **Laboratório de informática** | **Renanligno** |
| 6 | Corredor técnico | Os três inimigos comuns juntos. O encontro mais difícil da travessia. |
| 7 | **Pátio interno** | **Balarrals** |
| 8 | **Sala dos servidores** | **Marlombólico** |
| 9 | **A saída** | **Amandaconda** |

As travessias entre chefes são curtas — dois a três minutos. Elas são tecido conjuntivo, não
conteúdo. O jogo são as lutas.

## 9. Morte e nova tentativa

**Requisito, não polimento:** morrer num chefe devolve você para a porta daquele chefe,
imediatamente. Menos de dois segundos até estar lutando de novo. Sem refazer travessia, sem
tela de carregamento, sem cutscene repetida.

Num jogo que é feito de repetição, atrito no retry é a única coisa que faz o jogador
desistir de verdade.

Existe um ponto de descanso antes de cada chefe, que também recarrega a cura.

## 10. Progressão

Não existe. Sem experiência, sem upgrade, sem item novo, sem build.

Você não fica mais forte — **você fica melhor**. É o contrato do gênero, e por acaso é
também a decisão de escopo mais econômica do documento.

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

- Seleção de personagem (descartado — um personagem jogável, mais polido)
- Mundo aberto, exploração, mapa ramificado, atalhos
- Qualquer chefe além dos cinco
- Qualquer inimigo comum além dos três
- Inventário, loot, upgrade, level up, builds
- Multiplayer ou co-op
- Cutscenes longas, animação facial, lipsync
- Escudo e aparo (metas esticadas)
- Qualquer linha de C++
- Modelagem 3D e animação próprias — tudo de biblioteca gratuita
