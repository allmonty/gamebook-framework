# Atributos e seu herói

Atributos são os números que descrevem o herói: quão hábil, quão saudável, quão sortudo, quão rico. Você escolhe quais atributos existem, como são rolados, como se chamam e qual deles significa "vivo". Depois o leitor cria o herói: rola, dá um nome e escolhe o equipamento.

## Presets: regras numa linha

Até aqui todo exemplo usou `"preset": "fighting-fantasy"`. Um preset é um conjunto de regras pronto:

| Preset | Atributos (rolagem inicial) | Vida | Lutas |
|---|---|---|---|
| `fighting-fantasy` | Habilidade `1d6+6`, Energia `2d6+12`, Sorte `1d6+6` | Energia | os dois rolam 2d6 + Habilidade; quem perde perde 2 |
| `d20-lite` | Força, Agilidade, Astúcia `1d4` cada, PV `2d6+8` | PV | 1d20 + Força contra 10 + Agilidade; dano 1d6 |

Aqui está o mesmo tipo de história com `"preset": "d20-lite"`:

```gamebook
examples/04-stats-and-hero/d20-hero
```

Tudo que você escrever junto ao preset **sobrescreve campo por campo**. O mais comum é trocar o nome de um atributo, porque os presets vêm em inglês. A versão em português de todo exemplo faz exatamente isso:

```json
"rules": { "preset": "d20-lite", "stats": { "might": { "label": "Força" } } }
```

## Seus próprios atributos

Deixe o preset de fora e defina tudo: os `stats` e qual deles é a vida (`health`).

```gamebook
examples/04-stats-and-hero/ghost-market
```

```json
"rules": {
  "health": "nerve",
  "stats": {
    "nerve": { "label": "Coragem", "roll": "2d6+6", "max": true },
    "wits":  { "label": "Astúcia", "roll": "1d6" },
    "gold":  { "label": "Ouro",    "roll": "1d6", "limit": 10 }
  }
}
```

- `label` é o que o leitor vê; o id (`nerve`) é o que você escreve em condições e efeitos.
- `roll` usa notação de dados: `1d6` é um dado de seis lados, `2d6+6` são dois dados mais 6, e um número puro como `"3"` é um valor fixo. O capítulo 5 trata de dados.
- `"max": true` faz da rolagem inicial um teto: curas nunca passam dele.
- `limit` é um teto fixo (schema 5): aqui o ouro nunca passa de 10.
- `health` diz qual atributo significa vida. Quando chega a 0, o leitor morre, onde quer que esteja.
- Nenhum atributo fica abaixo de 0, a não ser que você dê a ele um `min` (abaixo).

### Mudando atributos

Atributos mudam com efeitos em páginas, escolhas e itens:

| Efeito | Significado |
|---|---|
| `{ "stat": "nerve", "add": -4 }` | perde 4 de Coragem (números positivos somam) |
| `{ "stat": "gold", "set": 0 }` | deixa o Ouro em exatamente 0 (schema 5) |

E condições os comparam: `{ "stat": "gold", "gte": 3 }` (3 ou mais), `lte` (ou menos), `eq` (exatamente).

### Abaixo de zero

Em jogos de mesa um atributo muitas vezes é um modificador somado a uma rolagem, e um herói fraco ou amaldiçoado tem um negativo: "Força -2". Dê ao atributo um `min` e ele pode descer até lá (schema 8):

```gamebook
examples/04-stats-and-hero/cursed-gauntlet
```

```json
"rules": { "preset": "d20-lite", "stats": { "might": { "min": -3 } } }
```

O `bonus` de -4 da manopla agora leva a Força abaixo de zero, e o `1d20 + might` da porta sente isso. Efeitos e bônus param no `min`, como param em 0 para qualquer outro atributo. O atributo de `health` não pode ter um: em 0 o herói está morto.

### Bônus com condição

O `bonus` de um item (capítulo 3) conta enquanto o item é carregado. Alguns bônus dependem de mais: um herói sem nenhuma arma luta com -4 de Habilidade. Escreva isso uma vez nas regras (schema 8):

```gamebook
examples/04-stats-and-hero/unarmed
```

```json
"bonuses": [
  { "if": { "not": { "any": [ { "has": "sword" }, { "has": "club" } ] } },
    "bonus": { "skill": -4 } }
]
```

Enquanto o `if` valer, o bônus conta em toda parte, como o de um item: testes, lutas, condições, `{skill}` no texto e a barra de atributos. Perca a espada e ele começa; pegue o porrete e ele para. A condição vê os bônus de itens mas não os de outras regras, então uma regra não consegue se ligar ou desligar sozinha.

## Preços e atributos que apontam para atributos

Uma **quantidade** pode ficar onde vai um número, em `add`, `set` e condições: `{ "stat": "price" }` quer dizer "o valor atual de Preço", e `"times": -1` inverte o sinal (schema 5). Assim uma única escolha "Comprar" serve para todas as barracas:

```gamebook
examples/04-stats-and-hero/merchant-price
```

```json
{ "text": "Comprar", "to": "street",
  "if": { "stat": "gold", "gte": { "stat": "price" } },
  "effects": [ { "stat": "gold", "add": { "stat": "price", "times": -1 } }, { "give": "noodles" } ] }
```

Cada barraca define `price` quando você chega nela. O leitor vê Preço nos atributos, o que aqui funciona como etiqueta.

## Criando o herói

Adicione `creation` às regras (schema 5) e a história abre com uma tela de personagem:

```gamebook
examples/04-stats-and-hero/pick-your-kit
```

```json
"rules": {
  "preset": "fighting-fantasy",
  "rerolls": 3,
  "creation": {
    "name": true,
    "picks": [ { "id": "kit", "title": "Escolha duas coisas para levar", "count": 2, "options": [
      { "id": "torch", "label": "Uma tocha", "description": "Luz em lugares escuros.", "effects": [ { "give": "torch" } ] },
      { "id": "rope", "label": "Uma corda", "effects": [ { "give": "rope" } ] },
      { "id": "charm", "label": "Um amuleto da sorte", "effects": [ { "stat": "luck", "add": 1 }, { "set": "lucky" } ] }
    ] } ]
  }
}
```

- `rerolls`: quantas vezes o leitor pode rolar todos os atributos de novo (Fighting Fantasy permite 2). A última rolagem fica.
- `"name": true` pede o nome do herói; escreva `{name}` em qualquer texto para usá-lo.
- `picks`: grupos de opções, cada um com quantas escolher (`count`). Toda opção escolhida aplica seus `effects` antes da primeira página. `{ "set": "lucky" }` liga um **marcador** (flag), um interruptor que uma condição testa com `{ "flag": "lucky" }`; o capítulo 7 tem mais.

A tela de personagem aparece quando a história tem `creation` ou define seu próprio `rerolls`. Senão o herói é rolado em silêncio e a história começa na primeira página, como nos exemplos anteriores.

### Experimente

- No mercado fantasma, mude o `roll` do ouro para `"20"`. O limite ainda segura em 10.
- Em Escolha seu Equipamento, mude `count` para `1` ou adicione uma quarta opção.
- No mercado noturno, faça a jaqueta custar 2.
- No cofre, tire o `"min": -3`: a manopla agora para a Força em 0, e a porta fica mais fácil.
- Em Desarmado, troque `-4` por `-1`, ou tire o `{ "has": "club" }` para o porrete não ajudar mais.

A seguir: rolar dados quando importa.
