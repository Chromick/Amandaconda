# AMANDACONDA — Plano de 16 semanas

Contexto: uma pessoa, começando do zero na Unreal, entrega obrigatória de um jogo jogável
do começo ao fim.

## A regra que vale mais que este documento

**Cinza e jogável antes de bonito e quebrado.**

O erro que mata projeto de estudante não é falta de talento, é gastar seis semanas deixando
uma sala linda e chegar na entrega sem jogo. O prédio inteiro deve estar jogável de ponta a
ponta, em caixas cinzas sem textura, antes de você aplicar a primeira luz bonita. Isso está
planejado abaixo e não é negociável.

## Fases

### Semanas 1–2 — Aprender a engine (não faça o jogo ainda)

Resista à vontade de começar o AMANDACONDA. Faça os tutoriais oficiais da Epic, mexa no
template de primeira pessoa, quebre coisas de propósito.

**Entregável:** uma sala, você andando em primeira pessoa, uma porta que abre com E e um
interruptor que apaga a luz. Feito só com Blueprint.

### Semanas 3–4 — O protótipo que decide o projeto

Uma sala cinza, um cubo que é a Amandaconda, e os dois sentidos funcionando: vibração
(velocidade × tipo de piso) e calor (contraste com a temperatura da sala).

Este é o momento mais importante do semestre. **Se esconder de um cubo cinza já for tenso e
divertido, o jogo existe.** Se não for, você ainda tem tempo de mudar o design. Descobrir
isso na semana 3 é barato; na semana 12 é fatal.

**Entregável:** protótipo de furtividade jogável, sem arte nenhuma.

### Semanas 5–6 — Terminais e orçamento de energia

O sistema de terminais completo: câmeras, portas, luzes, alto-falantes, HVAC, e a tabela de
consumo de energia. O HVAC precisa realmente alterar o mapa térmico que o cubo usa.

**Entregável:** duas salas, um terminal, e você conseguindo manipular o cubo pelo terminal.

### Semanas 7–9 — Blockout do prédio inteiro

Os três níveis e os dezoito ambientes, em geometria cinza. Sem textura, sem iluminação de
verdade, sem som. Mas com todas as portas, terminais e rotas de patrulha no lugar.

**Entregável:** o prédio inteiro percorrível do início ao fim.

### Semana 10 — MARCO: fatia vertical

Pare de programar. Coloque três pessoas que nunca viram o jogo pra jogar na sua frente,
sem você explicar nada, e **não abra a boca**. Anote tudo que elas não entenderem.

Se aqui você já está atrasado, este é o momento de cortar escopo — e o corte certo é reduzir
de quatro NPCs para dois, não simplificar os sistemas.

### Semanas 11–12 — NPCs e o mecanismo de sacrifício

Os quatro personagens, os diálogos (texto, com áudio se der tempo), a lógica de quem está
onde, e o sistema de sacrifício: destrancar porta, mentir pelo alto-falante, não avisar.
Registro das escolhas para os finais.

**Entregável:** o jogo inteiro jogável com a narrativa funcionando, ainda cinza.

### Semanas 13–14 — Arte, luz e som

Só agora. Assets de biblioteca gratuita, iluminação, pós-processamento, e principalmente
**som** — num jogo de terror o áudio faz mais pela atmosfera do que qualquer coisa visual, e
é onde você tem o melhor retorno por hora investida.

**Entregável:** o jogo parecendo um jogo.

### Semana 15 — Finais, polimento e bugs

As quatro cenas finais, menu, checkpoints, e a caça aos bugs mais óbvios.

### Semana 16 — Build e reserva

Empacotar, testar o executável numa máquina que não é a sua (isso sempre quebra), gravar
vídeo de gameplay pra apresentação.

**Esta semana é reserva pra desastre.** Se você chegou aqui sem desastre, use pra polir. Não
planeje trabalho novo pra ela.

## Riscos e o que fazer

| Risco | Sinal de alerta | Reação |
|---|---|---|
| Escopo crescendo | Você teve uma ideia nova e boa | Anote num arquivo `IDEIAS.md` e não implemente. É pro próximo projeto. |
| A furtividade não é divertida | Semana 4 e o protótipo é chato | Redesenhe agora, não depois. Ainda dá tempo. |
| Travando na Unreal | Mais de um dia no mesmo problema | Procure a solução mais burra que funciona. Ninguém vai auditar seu Blueprint. |
| Atraso acumulado | Semana 10 e o blockout não fechou | Corte NPCs, corte salas. Nunca corte o polimento das últimas semanas. |
| Perda de arquivos | — | Git desde o primeiro dia, com Git LFS para os assets. Configure isso na semana 1. |

## Próximos passos imediatos

1. Instalar Unreal Engine 5 e a Epic Games Launcher
2. Inicializar o repositório git com `.gitignore` e `.gitattributes` de projeto Unreal
3. Criar o projeto em branco a partir do template de primeira pessoa, Blueprint
4. Começar os tutoriais da semana 1
