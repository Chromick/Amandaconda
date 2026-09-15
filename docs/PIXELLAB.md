# PixelLab — prompts AMANDACONDA

Gera → exporta → me manda o arquivo (Downloads ou chat) → eu encaixo no jogo.

## Ajustes da tela Characters (sempre)

| Campo | Valor |
|---|---|
| Camera | **Sidescroller** |
| Direction preferida | **South-East** (3/4, olhando pra direita) |
| Detail | Medium |
| Outline | Single color / Default |
| Fundo | Transparent se tiver opção |

Tamanhos sugeridos:

| Quem | Width × Height |
|---|---|
| Jogador | 32 × 48 |
| Chatana | 32 × 32 |
| Portara / Net | 40 × 48 |
| Minichefes | 48 × 56 |
| Amandaconda | 64 × 64 (cauda pode estourar — ok) |

---

## 1. Jogador — DESARMADO

Nada na mão. Nada nas costas. Arma entra depois, no código.

**Idle / base**

```
Side-view 2D platformer pixel art character, south-east 3/4 view facing RIGHT.
Thin college IT student, dark grey hoodie, blue jeans, messy black hair, pale skin, white sneakers.
UNARMED: empty hands at sides, NO weapon, NO keyboard, NO sword, NO axe, NO backpack, nothing on the back.
Hard pixels, no anti-aliasing, limited palette (~12 colors), black outline, amber accent #D89E4A sparingly.
Simple readable silhouette, about 40px tall. Transparent background.
```

Animações (Direction = **South-East**):

| Animação na PixelLab | Arquivo no jogo |
|---|---|
| Idle | `player/parado` |
| Walking (4 frames) | `player/andando` |
| Two-Footed Jump | `player/no_ar` |
| Throw Object | `player/lancar` (escola Especial / bola virus) |
| Punching (curto) — depois | `player/ataque_leve` (escola Físico) |

---

## 2. Inimigos comuns

Mesma regra dos chefes: **objeto monstro** + **marcas da pessoa**. South-East. Idle primeiro.  
As três são **meninas da turma** — o monstro é objeto, mas cabelo/rosto leem **femininos** (não corte masculino / não “menino de óculos”).

| Inimigo | Real (feminino) | Ficção (corpo) |
|---|---|---|
| **Chatana** | óculos + cabelo preto com franja/volume, cílios, “ri alto” | webcam/caixa de som |
| **Net** | cabelo **ruivo** longo/ondulado, laço ou brinco opcional | antena parabólica |
| **Portara** | cabelo preto ondulado longo, maçã mordida (Apple) | porta de metal andando |

### Chatana — representante chata (barulho)

Óculos/cabelo ok; regenerar se parecer menino. Não vira humanoide.

```
Side-view pixel enemy, south-east facing RIGHT. Tiny hostile FEMALE-coded monster: webcam + loudspeaker box hybrid (NOT a human body, NOT a boy).
Dark metal grey casing, amber LED #D89E4A when laughing, speaker grille like an open laughing mouth.
MUST feminine face cues on the box front: round glasses, long dark eyelashes under the lenses, tiny pink/red lip pixels or blush on the “cheeks” of the casing.
MUST: feminine SHORT-TO-MEDIUM BLACK hair with bangs / side-swept fringe and a little volume or a small hair clip — NOT a masculine buzz cut, NOT a boy hair tuft.
Two thin antennas. About 28-32px tall. Hard pixels, black outline, transparent BG.
Class-rep girl who screams — funny object with clearly feminine hair/face cues.
```

### Net — a outra chata (marca de longe)

```
Side-view pixel enemy, south-east facing RIGHT. Tall thin parabolic satellite dish antenna monster (NOT a human, NOT masculine).
Metal dish facing slightly toward camera/right, teal/slate #26605E.
MUST: LONG WAVY FEMININE RED / ginger hair #C45A2A flowing from the top/back of the dish like a girl’s mane — soft waves, volume, ends past the dish rim (readable red, not brown).
Optional small pink hair bow or tiny earring glint on the dish edge.
Small glowing lock-on LED. About 40-48px tall. Hard pixels, black outline, transparent BG.
Feminine sniper antenna that marks you. No walking legs.
```

### Portara — a chata da Apple (muro)

```
Side-view pixel enemy, south-east facing RIGHT. Tall walking metal DOOR on stubby feet (door body, not a person, not a male silhouette).
Slate / dark grey door, security window as an eye with long eyelashes, teal accents #26605E. About 48px tall.
MUST: LONG BLACK WAVY feminine hair cascading from the top of the door (soft curls/waves, shoulder-length or longer — girl hair, not short male crop).
MUST: bitten apple icon (Apple-logo style — fruit with a bite) on the door face, silver/white, readable.
Optional tiny lipstick mark on the window “mouth” area. Menacing but funny. Hard pixels, black outline, transparent BG.
```

---

## 3. Chefes — Idle (base)

Gera o **Idle** primeiro (South-East). **Não use** Walking / Punching / Jump prontos da PixelLab nos chefes — cada um tem animação própria (seção 4).

### Regra: simples, mas reconhecível

Cada chefe = **caricatura** (poucos pixels) + **2–3 marcas da pessoa real** + **1–2 marcas ficção**.  
Se o PixelLab “embelezar” e apagar a marca (ex.: loiro → prata), **regera** — não aceita.

| Chefe | Real (obrigatório no sprite) | Ficção (obrigatório) |
|---|---|---|
| LuanEvil | corpo grande, **cabelo curto** (corte masculino/pixie), sorriso, fone no pescoço | bandeja/armadura de bandejão, caramelo #F0B450 |
| Renanligno | jovem forte, cara séria/cansada | MacBook, atraso/glitch azul #2F6796 |
| Balarrals | mesmo corte/corpo do jogador (moletom, jeans, tênis), cabelo bagunçado | prata #7C8494, **sorriso torto debochado**, vibe espelho errado |
| Marlombólico | magro/alto, boné pra trás, **chinelo**, 1 mão no bolso, cara de tédio | glow neon #23A34A nos olhos, cabo/código glitch, “hackeia o jogo” |
| Amandaconda | **cabelo loiro ondulado**, óculos redondos + corrente, batom vermelho, blazer escuro / gola alta | escamas verdes num lado do rosto, **cauda**, olhos de cobra |

---

### LuanEvil (âmbar / caramelo) — idle OK no jogo

Cabelo curto + bandejão. Usar este personagem nas custom anims (o `andando` antigo foi apagado — regenerar).

Prompt (se precisar regenerar):

```

Side-view 2D boss pixel art, south-east facing RIGHT. SIMPLE readable silhouette but DETAILED villain presence, hard pixels, black outline, transparent BG. About 50-56px tall.

REAL LIFE (must read at tiny size — do not drop these):
- Large plus-size woman tank / soft heavy build — wide silhouette, not skinny, not armor-knight proportions.
- VERY SHORT dark-brown hair like a masculine buzz/crop or pixie cut — close to the scalp, ears visible, NO bun, NO ponytail, NO long hair, NO shoulder-length hair, NO hair on the back.
- Always smiling warmly (friendly face on intimidating body).
- Headphones hanging around her NECK (not on ears) — big earcups readable.
- Dark casual clothes + RU cafeteria apron vibe (not plate armor, not sword, not mace).

FICTION (cafeteria boss — keep human):
- Metal cafeteria TRAY pieces as shoulder pads / chest armor (tray shape, not knight pauldrons).
- Golden-amber / caramel accents #F0B450 on trays and trim.
- Soft but huge tank silhouette. Empty hands — NO weapons.

NOT a medieval warrior. NOT long hair. NOT a bun. NOT barefoot knight boots aesthetic.
She is the smiling RU bandejão tank with short hair and headphones on the neck.
```

### Renanligno (azul frio)

```
Side-view 2D boss pixel art, south-east facing RIGHT. Tall athletic young man, serious tired face, short dark hair.
Cold blue palette #2F6796. MUST hold a black MacBook under one arm (readable laptop slab).
Slightly late / out-of-sync vibe, optional tiny blue glitch near elbow. Hits like a truck, not skinny ghost.
Hard pixels, black outline, transparent BG. About 48px tall. Empty free hand.
```

### Balarrals (prata) — idle OK no jogo

Ataques = recolor das folhas do player. Idle é referência de rosto/paleta.

Prompt (se precisar regenerar):

```
Side-view 2D boss pixel art, south-east facing RIGHT. SIMPLE readable silhouette but DETAILED villain presence, hard pixels, black outline, transparent BG. Same proportions as the player hero (~40-44px tall).

REAL LIFE / twin of the hero (must match player body language):
- Thin college IT student silhouette — messy short dark hair (hood DOWN so the face reads), dark hoodie, blue jeans, white sneakers.
- Same posture and proportions as a normal side-scroller student hero — NOT taller, NOT bulkier, NOT a different costume.
- UNARMED idle: empty hands at sides (weapon only appears later / mirrored in code).

FICTION (mirror villain — this is what makes him a boss):
- Full body desaturated into moonlight silver / cold greys #7C8494 — hoodie, jeans, hair all washed silver (NOT colorful like the hero).
- MUST: crooked mocking grin (asymmetric smirk) + one eyebrow raised — smug face that makes you want to hit him.
- Eyes slightly wrong: pale silver iris or one eye a thin white glint.
- Optional: faint translucent silver afterimage / mirror ghost offset 2px behind him.
- Optional: thin vertical “crack” highlight on cheek or hoodie like a broken mirror shard (tiny, readable).
- Feels like YOU but reversed and laughing at you.

NOT hood up hiding the face. NOT friendly smile. NOT generic grey NPC. NOT a different hairstyle from the hero.
He is the hero’s silver mirror twin whose face is the mechanic.
```

### Marlombólico (verde neon) — idle OK no jogo

Assinatura: boné pra trás + 1 mão no bolso (+ chinelo quando der pra ler). Usar este personagem nas custom anims.

Prompt (se precisar regenerar):

```
Side-view 2D boss pixel art, south-east facing RIGHT. SIMPLE readable silhouette but DETAILED like a final-act villain, hard pixels, black outline, transparent BG. About 52-56px tall.

REAL LIFE (must read at tiny size — do not drop these):
- Very thin tall lazy college hacker, bored half-lidded face, slight smug smirk (not friendly).
- Backward dark baseball cap (MUST).
- Dark hoodie + loose pants; ONE hand permanently in the front pocket (MUST — other hand free or holding a phone).
- FLIP-FLOPS / chinelo on feet with visible straps (MUST — not boots, not barefoot).
- Relaxed slouch: looks like he is not trying, and that is the threat.

FICTION (villain presence — keep human body):
- Neon terminal green #23A34A glow in BOTH eyes (small bright pupils / iris glow).
- Thin ethernet or USB cable draped loosely around neck like a scarf, plug dangling.
- Tiny floating green code glyphs / glitch pixels near the free hand or shoulder (2-4 pixels of #23A34A).
- Dark clothes with neon-green trim or circuit-line stitch on hoodie sleeve.
- Optional: cracked phone in free hand showing green terminal text.

NOT a muscle boss. NOT barefoot. NOT hands out of pockets. NOT generic NPC hoodie guy.
He should feel like the guy who hacks YOUR game while wearing chinelo.
```

### Amandaconda (verde-petróleo + âmbar) — idle OK no jogo

Loira + óculos/corrente + cauda teal. Usar este mesmo personagem nas custom anims.

Prompt (se precisar regenerar):

```
Side-view 2D final boss pixel art, south-east facing RIGHT. SIMPLE readable silhouette, hard pixels, black outline, transparent BG. About 56-64px tall, wider canvas for tail.

REAL LIFE (must read at tiny size):
- DIRTY BLONDE / golden blonde wavy shoulder-length hair #E0C06A — NOT silver, NOT white, NOT blue, NOT teal hair.
- Round glasses with thin gold frames and a small beaded glasses-chain.
- Strong deep red lipstick.
- White turtleneck under a dark charcoal blazer (office IT / boss lady).
- Unimpressed cool expression. Small IT badge on lapel optional.

FICTION (keep light — mostly human):
- Olive-green snake scales ONLY on one cheek, temple, side of neck — face still mostly human.
- Optional yellow slit pupil (one eye).
- Long teal-petroleum #26605E snake TAIL behind her (biped legs + tail, NOT full lamia / no snake lower body).
- Amber #D89E4A accents on scale edges / tail tip only.

Do NOT make her hair match the tail color. Hair = blonde. Tail/scales = teal-green.
```

Se ainda vier loira “suja” demais pro cinza: gera de novo com a linha extra  
`hair is clearly yellow-blonde like straw gold, brightest part of the sprite after lipstick`.
---

## 4. Animações custom por chefe (NÃO usar preset)

Na PixelLab: **Custom animation** / prompt de animação (não Idle/Walk/Jump/Punch do menu).  
Direction = **South-East**. 4 frames (salvo onde diga 2 ou 3).  
Cole o prompt abaixo no campo da animação — o personagem já é o Idle do chefe.

### LuanEvil → `luanevil/`

Em **todos** os frames: **cabelo curto** (sem coque/longo), sorriso, fone, bandejas âmbar — nunca armadura medieval / maça.

**andando**

```
Heavy walk facing RIGHT. Plus-size smiling cafeteria tank, VERY SHORT dark crop/pixie hair (ears visible, NO bun/long hair).
Tray-armor shoulder pads bounce, headphones bounce on NECK, amber #F0B450. Slow weighty steps. 4 frames.
Hard pixels, transparent BG. No weapons. Not a knight.
```

**investida** (rush / shoulder charge)

```
Charge facing RIGHT. Short-haired plus-size woman leans forward, cafeteria trays as pads, arms tucked, fierce grin.
Headphones on NECK. Amber caramel. 4 frames (windup → rush → contact → recover). Hard pixels, transparent BG.
NO mace, NO plate knight armor, NO long hair.
```

**pisada** (espalha caramelo no chão)

```
Heavy stomp facing RIGHT. Short crop hair, smile, trays rattle, headphones on neck.
Amber caramel #F0B450 puddle under foot on impact (not blood). 4 frames. Hard pixels, transparent BG.
```

**fase2_fone** (meia vida — coloca o fone)

```
Transition: short-haired smiling tank reaches for headphones on NECK and puts ONE earcup on her ear.
Still smiling, more locked-in. Short hair stays short. 3 frames. Facing RIGHT. Hard pixels, transparent BG.
```

**cambaleando / dano / morte**

```
Stagger: rocks back, smile awkward, short hair, trays tilted, headphones neck/ear — 2 frames.
Hit: 1 frame flinch, smile unbroken.
Death: sinks to knees, smile softens, headphones slip — 2 frames, no gore.
Facing RIGHT. Hard pixels, transparent BG. Still cafeteria boss, not knight.
```

---

### Renanligno → `bosses/renanligno/`

Fantasma atrasado = **código** (mesmo sprite com delay/alpha). Nas artes ele só age “fora de sincronia”.

**andando**

```
Side-scroller walk facing RIGHT, tall athletic young man, cold blue #2F6796. Steps look slightly LATE — weight lands a beat after the stride.
MacBook under one arm or small glitch afterimage near elbow. Tired serious face. 4 frames. Hard pixels, transparent BG.
```

**golpe_atrasado** (soco/golpe que “atrasa”)

```
Melee attack facing RIGHT where the STRIKE lands late: windup holds long, then sudden punch/kick on last frames.
Cold blue palette. Glitch afterimage of the arm on the hit frame. MacBook tucked or floating. 4 frames. Hard pixels, transparent BG.
```

**estocada**

```
Forward thrust / lunging strike facing RIGHT with laptop corner or fist like a delayed spear. Body snaps forward late.
Blue accents, serious face. 4 frames (telegraph → hold → snap → recover). Hard pixels, transparent BG.
```

**cambaleando / dano / morte**

```
Stagger: tall blue fighter desyncs, body and afterimage misaligned, 2 frames.
Hit: 1 frame flinch, glitch tear.
Death: collapses, MacBook drops, blue fade — 2 frames, no gore. Facing RIGHT. Hard pixels, transparent BG.
```

---

### Balarrals → não gera folha de ataque

Idle novo (sorriso torto + prata). **Andar / pular / atacar = cópia recolor do jogador** (#7C8494).  
Só regenera Idle SE; o resto a gente clona no pipeline.

---

### Marlombólico → `marlombolico/`

Em **todos** os frames: boné pra trás, **chinelo**, 1 mão no bolso, olhos neon, cabo no pescoço.

**andando**

```
Lazy walk facing RIGHT. Thin tall hacker, backward cap, FLIP-FLOPS flapping, ONE hand in pocket.
Neon green #23A34A eye glow, ethernet cable scarf bounces, tiny green code pixels trail the free hand.
Bored smug face. 4 frames. Hard pixels, transparent BG. Still looks effortless.
```

**comando** (aponta / “manda o minion”)

```
Lazy command facing RIGHT: free hand flicks / points; green glyphs bloom at fingertips; OTHER hand NEVER leaves pocket.
Eyes flare neon. Cap, chinelo, cable scarf stay. Bored smirk. 4 frames (raise → point → hold → lower).
Hard pixels, transparent BG. Calling hacks/adds, not a punch.
```

**glitch** (teleporte / stutter)

```
Glitch stutter facing RIGHT: body tears into neon-green #23A34A horizontal slices / offset copies then reforms.
Hand stays in pocket. Cap + chinelo + cable readable through the glitch. Eye glow intensifies. 4 fast frames.
Hard pixels, transparent BG.
```

**cambaleando / dano / morte**

```
Stagger: annoyed shrug, eyes flicker, cable swings, hand in pocket, 2 frames.
Hit: 1 frame flinch, still bored, green spark.
Death: sits on the floor in flip-flops, phone/cable drop, eye glow dies — 2 frames, no gore.
Facing RIGHT. Hard pixels, transparent BG.
```

---

### Amandaconda → `amandaconda/`

Canvas largo pela **cauda**. Em **todos** os frames: **cabelo loiro**, óculos+corrente, batom vermelho, blazer/gola, cauda teal (cabelo ≠ cor da cauda).

**andando**

```
Side-scroller walk facing RIGHT. DIRTY BLONDE wavy hair #E0C06A (not silver/blue). White turtleneck + dark blazer.
Round glasses + chain, red lipstick. Teal #26605E tail sways opposite steps. Scales only on one side of face/neck.
Unimpressed. 4 frames. Hard pixels, transparent BG. Wide canvas for tail.
```

**chicotada** (cauda)

```
Tail whip facing RIGHT: blonde woman plants feet, teal tail coils then cracks like a whip. Amber tip optional.
Glasses + red lipstick stay. Unimpressed. 4 frames. Hard pixels, transparent BG. Wide canvas.
```

**bote**

```
Lunge facing RIGHT: blonde biped + teal tail push, glasses chain swings, scales flash on one cheek.
NOT full serpent. 4 frames. Hard pixels, transparent BG.
```

**enrosco**

```
Coil trap: teal tail spirals in front as grab zone; upper body calm blonde office-snake woman, unimpressed.
4 frames. Facing RIGHT. Hard pixels, transparent BG. Wide canvas.
```

**mudanca_de_fase** (3 frames)

```
Phase shift: more olive scales on face/arms, colder eyes, amber glow on scales, tail thicker — HAIR STAYS BLONDE.
Glasses stay. 3 frames. Facing RIGHT. Hard pixels, transparent BG.
```

**cambaleando / dano / morte**

```
Stagger: tail braces, glasses tilt, blonde hair, 2 frames.
Hit: 1 frame flinch, red lipstick unbroken.
Death: kneels, tail limp, glasses chain hangs — 3 frames, dignified, no gore.
Facing RIGHT. Hard pixels, transparent BG.
```
---

## 5. Como me mandar

1. Export ZIP ou GIF/PNG da animação custom  
2. Salva em `Downloads`  
3. Diz o que é: `luanevil investida`, `renanligno golpe_atrasado`, etc.

Eu encaixo e você aperta `F5` no jogo.

## 6. Conta / MCP (opcional)

[pixellab.ai](https://www.pixellab.ai/) → Account → token → [vibe-coding](https://www.pixellab.ai/vibe-coding) escolhendo Cursor, se quiser que eu gere daqui.
