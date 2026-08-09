# AMANDACONDA — Fase 2: Unreal 3D

**Prazo:** ~8 semanas
**Ferramenta:** Unreal Engine 5, apenas Blueprint, sem C++
**Perspectiva:** terceira pessoa
**Equipe:** 1 pessoa

---

## Aviso de escopo, e precisa ser resolvido cedo

Oito semanas, sozinho, começando do zero na Unreal, **não dão pra reconstruir o jogo inteiro
em 3D.** Isso não é pessimismo, é aritmética: só aprender a engine consome as duas primeiras
semanas, e sobram seis pra combate, cinco chefes, travessia, arte e som.

Você chega nesta fase com uma vantagem enorme — o design está resolvido e os números estão
prontos — mas vantagem de design não substitui tempo de implementação.

**Pergunte ao professor o quanto antes** se a fase 2 precisa ser o jogo completo ou se pode
ser uma parte bem feita. As duas respostas mudam o plano abaixo:

**Se puder ser uma parte** (o cenário realista): faça a **Amandaconda completa mais o
Balarrals**, com a cena da porta. Um chefe final impressionante em 3D vale mais que cinco
chefes apressados, e é a fatia que melhor demonstra o projeto.

**Se tiver que ser o jogo inteiro:** os cinco chefes ficam com três ataques e uma fase cada,
inclusive a Amandaconda, a travessia vira dois corredores curtos, e você aceita que o
acabamento vai ser modesto. É factível, mas é apertado.

O plano abaixo assume o primeiro cenário e marca o que muda no segundo.

## A vantagem que você traz da fase 1

Nada de design precisa ser decidido. Você já sabe que o jogo é bom, já sabe o que cada chefe
ensina, e já tem a [tabela de ajuste](NUMEROS.md) preenchida.

**Transcreva a tabela antes de programar qualquer coisa.** Preparação de golpe, janela de
punição, invencibilidade, vigor, vida, limiares de fase — tudo isso já está resolvido e é
verdade em qualquer engine. O que vai precisar de reajuste é praticamente só distância e
alcance, que mudam de significado quando o jogo ganha profundidade.

## O plano de 8 semanas

### Semanas 1–2 — Aprender a engine

Não comece o AMANDACONDA. Tutoriais oficiais da Epic, template de terceira pessoa, Blueprint,
quebrar coisas de propósito.

Baixe o **Game Animation Sample Project** logo no começo — ele resolve andar, correr e virar
com qualidade profissional, de graça, e é a maior economia de tempo disponível.

**Entregável:** personagem se movendo bem, câmera funcionando, uma animação disparada por
botão.

### Semanas 3–4 — Combate contra um boneco

Ataque leve com combo, pesado carregável, rolamento com invencibilidade, vigor, lock-on,
detecção de acerto, reação de dano, som e tranco de impacto.

Use os números da fase 1 desde o primeiro minuto, em vez de descobrir de novo.

**MARCO da semana 4:** bater no boneco tem que ser gostoso. Se não for, conserte antes de
seguir.

### Semana 5 — Sistema de chefe e o Balarrals

Barra de vida, portão de arena, música, ponto de descanso, atordoamento, morte e retorno
imediato.

O Balarrals de novo primeiro, pelo mesmo motivo de sempre: ele reaproveita cem por cento do
moveset do jogador, então construir ele é construir o sistema.

### Semanas 6–7 — A Amandaconda

Duas fases, os oito ataques, a transição, a arena da saída, e a cena da porta com o cigarro,
a xícara no parapeito e o final.

*Se a fase 2 precisar do jogo inteiro:* aqui entram os quatro minichefes com três ataques
cada, e a Amandaconda perde a segunda fase.

### Semana 8 — Arte, som e entrega

Iluminação, chuva, pós-processamento, assets de biblioteca. Som — cada ataque com preparação
sonora distinta. Menu, cartões de entrada, créditos, empacotar e testar em outra máquina.

Reserva pra desastre.

## Decisões de produção herdadas

**A Amandaconda é bípede com cauda longa presa atrás**, animada por física ou spline. A lâmia
com cauda no lugar das pernas exige modelagem e rigging próprios, o que não cabe. A lâmia fica
só na arte promocional e na cena da porta. *(Em 2D isso não era problema; em 3D é.)*

**Os inimigos comuns são objetos, não pessoas.** Chatana, Portara e Net não precisam de
esqueleto nem de ciclo de caminhada, e foi de propósito.

## Recursos gratuitos

| Recurso | Pra que serve |
|---|---|
| **Game Animation Sample Project** (Epic) | Locomoção em terceira pessoa pronta e boa |
| **Mixamo** | Ataques, esquivas, reações de dano |
| **MetaHuman** | Rostos realistas. Escaneie as pessoas reais com Polycam ou KIRI Engine e use Mesh to MetaHuman |
| **Fab / Quixel Megascans** | Prédio, pátio, arena |
| **Meshy** ou **Tripo** | Geração de 3D por IA, só para os objetos: balde de pipoca, cadeira, antena, porta. Nunca para humanoides. |
| **Freesound, Pixabay** | Som e música livres |

MetaHumans são pesados, mas o jogo nunca tem mais de duas pessoas em cena. Não coloque as
cinco juntas.

## Riscos e reações

| Risco | Sinal de alerta | Reação |
|---|---|---|
| Escopo grande demais | Semana 5 e o combate não fechou | Corte para Amandaconda apenas. Fale com o professor. |
| Combate não é gostoso | Semana 4, bater no boneco é sem graça | Pare. Confira contra a tabela da fase 1. |
| Refazendo design já resolvido | Você está discutindo mecânica de novo | O GDD está fechado. Isto é fase de execução. |
| Rigging da cauda | Mais de dois dias | Cauda mais curta, ou só física simples. Não modele. |
| Perda de arquivos | — | Git com Git LFS. Configure na semana 1. |
