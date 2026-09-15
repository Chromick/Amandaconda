# Agente autônomo — como ligar e desligar

Controle em um arquivo:

```json
// AUTONOMOUS_MODE.json
{ "enabled": true }
```

| Valor | Comportamento |
|-------|----------------|
| `true` | O agente entra no loop (bugs → gameplay → …), documenta e continua. |
| `false` | O agente **não** auto-itera; só faz o que você pedir. |

## Comandos rápidos no chat

- `liga o autônomo` — ativa e continua trabalhando
- `desliga o autônomo` — desativa e para o loop

## Git

- Repo: [Chromick/Amandaconda](https://github.com/Chromick/Amandaconda)
- Branch Godot: `godot-4`
- `master` permanece a fase Pygame / docs

## Progresso

Ver `AUTONOMOUS_PROGRESS.md` após cada ciclo.
