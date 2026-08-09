# AMANDACONDA — Documento de Design

**Versão:** 0.1 (conceito fechado)
**Engine:** Unreal Engine 5 — Blueprint apenas, sem C++
**Perspectiva:** Primeira pessoa
**Duração alvo:** 30 a 40 minutos
**Equipe:** 1 pessoa
**Prazo:** 1 semestre (~16 semanas)

---

## 1. Pitch

Você é bolsista do laboratório de informática. Ficou até tarde porque seu trabalho do
semestre sumiu do servidor. Quando tenta ir embora, o prédio está trancado — e a Amanda,
chefe da TI, ainda está lá. Só que não do jeito que você conhece ela.

Você não tem arma, não tem força e não sabe brigar. O que você tem é acesso de
administrador ao prédio inteiro. Portas, câmeras, iluminação, ar-condicionado, alto-falantes.

E tem mais gente presa aqui com você.

## 2. Pilares de design

Toda decisão de design deste projeto deve poder ser justificada por um destes quatro pilares.
Se uma ideia não serve a nenhum deles, ela está fora.

1. **Você vence com conhecimento técnico, não com violência.** A fantasia de poder é ser
   bom de TI. Nunca existe a opção de lutar.
2. **A ameaça tem regras claras e aprendíveis.** O jogador deve conseguir explicar em voz
   alta como a Amandaconda funciona depois de vinte minutos de jogo. Nada de comportamento
   aleatório.
3. **Toda decisão difícil é tomada através de uma interface.** Você nunca empurra ninguém.
   Você destranca uma porta, ou não avisa pelo rádio. Mata-se com permissão de administrador.
4. **Comédia primeiro, horror depois.** O terror não vem de sustos, vem de perceber
   retroativamente o que você fez enquanto achava graça.

## 3. O jogador

Estudante de TI, bolsista/estagiário do laboratório de informática. Primeira pessoa, sem
corpo visível além das mãos.

**O que ele pode fazer**

| Ação | Custo / consequência |
|---|---|
| Andar | Vibração baixa |
| Agachar e andar | Vibração quase nula, movimento lento |
| Correr | Vibração alta, fôlego limitado (poucos segundos) |
| Interagir com terminais | Fica parado e vulnerável enquanto usa |
| Usar lanterna do celular | Consome bateria, não afeta a detecção dela |
| Carregar/arrastar objetos | Vibração alta |

**O que ele não pode fazer:** lutar, se defender, correr por muito tempo, escalar,
sobreviver a um encontro direto.

**Recursos:** bateria do celular (lanterna e leitura de arquivos), crachá de estagiário
(nível de acesso, sobe conforme o jogo), fôlego.

## 4. A Amandaconda

Chefe do setor de TI. **Está sempre em forma transformada.** Só retorna à forma humana
quando se alimenta — e volta a transformar quando a fome retorna.

### 4.1 Estados

| Estado | Comportamento |
|---|---|
| **Saciada (humana)** | Anda pelos corredores como uma pessoa normal. Conversa com você. Não ataca. Cronômetro correndo. |
| **Faminta (patrulha)** | Transformada. Percorre rotas pelo prédio procurando estímulo. |
| **Alerta** | Detectou vibração ou calor. Vai investigar a origem, devagar. |
| **Perseguição** | Localizou a presa. Rápida. Só se quebra saindo do alcance dos dois sentidos. |
| **Alimentando** | Cena. Ela some do mapa por um período. Volta ao estado saciada. |

O cronômetro de fome é a batida rítmica do jogo. O jogador sempre sabe, aproximadamente,
quanto tempo de paz ainda tem.

### 4.2 Os dois sentidos

Ela **enxerga muito mal**. Escuro não te protege dela — só atrapalha você. Isso é uma
subversão deliberada da expectativa de jogo de furtividade, e o jogo deve ensinar isso cedo
e de forma memorável.

**Vibração.** Ela sente o chão. A detecção é função da sua velocidade multiplicada pelo tipo
de piso. Carpete abafa quase tudo. Piso frio, escada metálica e piso elevado do CPD
propagam longe. Objetos caindo e cadeiras arrastadas geram picos de vibração.

**Calor.** Ela enxerga contraste térmico. O que importa não é a sua temperatura absoluta, é
a **diferença entre você e o ambiente da sala**. Isso cria um mapa térmico do prédio:

- **Sala dos servidores, casa de máquinas:** muito quente, você desaparece. É o esconderijo
  mais seguro do prédio e também é por onde ela mais passa.
- **Corredores, salas comuns:** neutro, detecção normal.
- **Salas com ar-condicionado no máximo, câmara fria da cantina:** frio, você brilha.
  Praticamente uma sentença de morte.

O jogador controla o HVAC pelos terminais, e portanto **pode reescrever o mapa térmico do
prédio**. Essa é a mecânica-assinatura do jogo.

## 5. O sistema de terminais

Cada computador do prédio é um painel de controle. O jogador senta, e enquanto está sentado
está vulnerável.

- **Câmeras** — ver a localização dela em setores energizados.
- **Portas magnéticas** — trancar e destrancar remotamente.
- **Iluminação** — acender e apagar setores. Não afeta ela. Afeta você e os NPCs.
- **Alto-falantes** — disparar áudio num setor, gerando vibração falsa. É a principal
  ferramenta de manipulação.
- **HVAC** — aquecer ou resfriar salas individualmente. Cria e destrói esconderijos.
- **Arquivos e e-mails** — onde mora a narrativa inteira. Chamados de TI, atas, planilhas.

### 5.1 O orçamento de energia

O gerador não aguenta tudo ligado. O jogador distribui uma quantidade limitada de energia
entre os setores, e cada sistema consome. Ligar o aquecimento da ala leste pode derrubar as
câmeras da ala oeste.

Isso é o coração sistêmico do jogo: uma única decisão legível, tomada dezenas de vezes, com
consequências diferentes toda vez. É também a mecânica de escopo mais barato do documento —
são números numa tabela.

## 6. O elenco

Quatro NPCs. Cada um tem uma função mecânica (o que ele te dá) e uma função dramática (o que
custa perdê-lo). Todos podem sobreviver. Salvar todos é o caminho difícil.

**Seu Valdir** — Segurança, 60 e poucos anos. Tem as chaves físicas de tudo e não entende
nada de computador. Acha a Amanda "uma moça tão prestativa". É a comédia do primeiro ato e a
dor do terceiro.

**Larissa** — Sua colega de turma, presa ali pelo mesmo motivo que você. É mais competente
que você e sabe disso. Se sobreviver, é quem realmente te ajuda a chegar na verdade.

**Professor Anselmo** — Ficou corrigindo prova. Arrogante, foi o chamado idiota dele que te
prendeu no prédio. É o NPC que o jogo *convida* você a sacrificar. Resistir a essa tentação
é uma escolha que o jogo registra.

**Kauã** — O outro estagiário da TI, entrou antes de você. Sabe alguma coisa e desconversa.
É a chave da revelação final: ele foi o candidato anterior.

## 7. O prédio

Bloco de TI da faculdade. Três níveis, compacto e vertical.

**Térreo** — Recepção, catraca eletrônica (a saída trancada), Laboratório 1 (início do jogo),
banheiros, cantina desativada com a câmara fria.

**Primeiro andar** — Salas de aula, sala dos professores, Laboratório 2, e a sala da chefia
de TI (o objetivo do terceiro ato).

**Subsolo** — Sala dos servidores (o forno), casa de máquinas, almoxarifado, arquivo morto e
a saída de serviço.

Cerca de dezoito ambientes no total, com forte reaproveitamento de assets. Todos revisitados
pelo menos duas vezes ao longo do jogo, em condições diferentes.

## 8. Estrutura

**Ato 1 — "Só mais um chamado" (~10 min).** Tutorial disfarçado. Você desce pra atender um
chamado bobo no subsolo e aprende a usar terminais. Ao voltar, a catraca está travada. Pela
câmera, você vê alguma coisa no corredor que não faz o menor sentido. Ainda é engraçado.

**Ato 2 — "Ela tem fome" (~20 min).** Você aprende as regras dela na prática. Encontra os
quatro NPCs. Descobre o HVAC e o mapa térmico. Aqui acontece a primeira morte — por escolha
sua ou por você ter chegado tarde demais. O tom vira e não volta.

**Ato 3 — "Recursos Humanos" (~10 min).** A sala da chefia. Os arquivos. A lista de alunos
"evadidos" que nunca evadiram. Kauã conta o que sabe. O clímax não é uma luta: é uma conversa
com a Amanda humana, de manhã, tomando café.

## 9. Finais

A verdade: **o cargo é transmissível.** A chefe anterior passou pra Amanda. Amanda está velha
demais pra isso e precisa de um sucessor — alguém com acesso administrativo, que conheça o
prédio e que se prove capaz de sacrificar as pessoas certas pra manter o sistema funcionando.
A noite inteira foi a prova.

E o detalhe cruel: **a Amanda humana não sabe.** Alimentada, ela é uma pessoa boa e cansada
que gosta de você e quer te ver formado. Você entregou colegas pra alguém que vai chorar por
eles amanhã.

Todos os finais usam a **mesma cena** — a sala da chefia, de manhã, ela oferecendo café. O
que muda é o diálogo e o epílogo, conforme dois eixos: quantos sobreviveram e quanto da
verdade você descobriu.

| Final | Condição |
|---|---|
| **O Sucessor** | Sacrificou pessoas, descobriu a verdade, aceita. Corte para você, anos depois, entrevistando um bolsista novo. |
| **A Recusa** | Descobriu tudo e recusa. Ela não te impede. Você sai — e o prédio continua lá, e o próximo também. |
| **Noite Limpa** | Todos os quatro sobreviveram. O caminho mais difícil. Vocês saem juntos ao amanhecer e ninguém acredita. A Amanda continua chefe da TI. |
| **Ignorância** | Escapou sem descobrir nada. Curto e insatisfatório de propósito. Existe para provocar a rejogada. |

## 10. Tom e referências

A comédia vem do cenário, não de piadas escritas: chamados de TI reais e absurdos, post-its
passivo-agressivos, fita crepe no rack escrito "NÃO DESLIGAR (sério)", senha do wi-fi
colada no monitor, aquele professor que não sabe anexar arquivo. Tudo que qualquer estudante
brasileiro reconhece na hora.

O horror vem da sequência: você riu do Anselmo por vinte minutos e depois destrancou a porta
dele.

**Referências:** *Alien: Isolation* (inimigo único com regras aprendíveis), *Papers, Please*
(crueldade cometida através de burocracia), *Firewatch* (personagens por voz, sem animação
facial), *Duskers* (você joga por interfaces, não com as mãos).

## 11. Fora de escopo

Lista explícita do que **não** será feito. Serve para resistir à tentação no meio do semestre.

- Combate de qualquer tipo
- Multiplayer
- Mais de um prédio, mundo aberto, mapa externo
- Animação facial e lipsync — NPCs são voz e texto
- Personagem em terceira pessoa
- Sistema de inventário ou crafting
- Save livre — apenas checkpoints por ato
- Qualquer linha de C++
- Modelagem 3D própria — todo asset vem de biblioteca gratuita
