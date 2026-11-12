# Itens

Chaves, poções, espadas, cordas: as coisas que o leitor pega mudam o que ele pode fazer. Neste capítulo você declara itens, entrega e tira itens, tranca escolhas atrás deles, deixa o leitor usá-los e decide quanto cabe na mochila.

## Chaves e portas trancadas

```gamebook
examples/03-items/locked-door
```

Três peças novas trabalham juntas aqui:

1. **O item é declarado** uma vez, no topo do arquivo, em `items`. Ele tem um id (`rusty-key`), um `name` que o leitor vê e uma `description` opcional:
   ```json
   "items": { "rusty-key": { "name": "Chave enferrujada", "description": "Ferro velho, mais velho que a cidade." } }
   ```
2. **Uma página o entrega.** Os `effects` de uma página acontecem quando o leitor chega nela: `{ "give": "rusty-key" }`. Efeitos também podem ficar numa escolha, e acontecem quando ela é tomada.
3. **Uma escolha precisa dele.** `"if": { "has": "rusty-key" }` tranca a porta até a chave estar na mochila. O aplicativo diz o motivo: "Precisa: Chave enferrujada". Essa escolha também tem `{ "take": "rusty-key" }`, porque a chave quebra na fechadura.

Itens são únicos: o leitor tem a chave enferrujada ou não tem. Dar duas vezes não muda nada.

> Experimente: revise as prateleiras duas vezes. A chave é dada de novo, mas você continua com uma só. O capítulo 7 mostra como fazer uma página dar a recompensa uma única vez.

## Itens que o leitor usa

Um item com `use` ganha um botão **Usar** na mochila. Usar aplica os efeitos dele e o gasta. Isso pede `"schema": 2` ou mais.

```gamebook
examples/03-items/healing-potion
```

```json
"potion": {
  "name": "Poção de cura",
  "use": { "effects": [ { "stat": "stamina", "add": 4 } ], "when": ["story"] }
}
```

- `effects`: o que acontece. Aqui a Energia sobe 4. (Efeitos em atributos estão no capítulo 4; `add` também pode ser negativo.)
- `when`: onde pode ser usado: `"story"` numa página normal, `"combat"` numa luta, ou os dois: `["story", "combat"]`.
- Numa luta, usar um item normalmente custa a rodada. Use `"combatCost": "free"` para itens que não custam.

A Energia nunca passa do valor inicial: a poção não cura além do máximo.

## Itens que melhoram você

Com `bonus` um item muda um atributo enquanto estiver na mochila (schema 5). Largou o item, o bônus vai junto.

```gamebook
examples/03-items/rune-blade
```

O portão pede `{ "stat": "skill", "gte": 12 }`: Habilidade 12 ou mais (`gte` quer dizer "maior ou igual"; `lte` é "menor ou igual", `eq` é "igual"). Poucos heróis começam tão hábeis, mas a lâmina soma 3. Olhe o valor da Habilidade quando você a pegar. Bônus valem em tudo: condições, testes de dados e lutas.

## Uma mochila com espaço limitado

Sem regras, a mochila guarda tudo. Para o espaço importar, adicione `inventory` em `rules` (schema 3):

```json
"rules": { "preset": "fighting-fantasy", "inventory": { "capacity": 2, "pickup": "choose" } }
```

```gamebook
examples/03-items/full-pack
```

- `capacity` é quantos itens cabem.
- `"pickup": "choose"` transforma cada `give` numa **oferta**: o leitor decide levar ou deixar e, com a mochila cheia, o que largar no lugar. A história espera até cada oferta ser resolvida.
- Um item com `capacity` própria é um **recipiente** (a bolsa): ele dá espaços e não ocupa nenhum.

Como o leitor pode deixar um item para trás, nunca faça de um item oferecido o único jeito de vencer. Aqui a escotilha abre com o pé de cabra *ou* com a corda.

## Ladrões e enchentes

Com `"pickup": "auto"` (o padrão) um `give` adiciona o item na hora e, se a mochila estiver cheia, o item é recusado. `{ "takeAll": true }` esvazia a mochila de uma vez: um ladrão, uma enchente, uma revista na prisão.

```gamebook
examples/03-items/the-thief
```

Leia o registro acima da página: a gema é recusada por falta de espaço e, depois, a moeda some.

## O que você aprendeu

| Escreva | Onde | Significado |
|---|---|---|
| `"items": { "id": { "name": ... } }` | topo do arquivo | declara um item |
| `{ "give": "id" }` / `{ "take": "id" }` | `effects` de página ou escolha | adiciona / remove |
| `{ "takeAll": true }` | `effects` | esvazia a mochila (schema 3) |
| `{ "has": "id" }` | `if` de uma escolha | precisa do item |
| `"use": { "effects": [...], "when": [...] }` | um item | item usável (schema 2) |
| `"bonus": { "skill": 3 }` | um item | bônus enquanto carregado (schema 5) |
| `"inventory": { "capacity": 2, "pickup": "choose" }` | `rules` | mochila limitada, ofertas (schema 3) |
| `"capacity": 2` | um item | um recipiente |

A seguir: os atributos do herói e como rolá-los.
