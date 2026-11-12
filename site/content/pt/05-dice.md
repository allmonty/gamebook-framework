# Dados

Um livro-jogo sem dados é uma história de escolher caminhos. Com dados, os atributos do leitor começam a importar: um herói hábil salta o vão mais vezes, um sortudo desvia do dardo. Este capítulo trata de testes de dados, do Teste de Sorte e de tabelas de resultado aleatório.

## Notação de dados

Onde o formato pede dados, você escreve como um jogador de mesa:

| Escreva | Significa |
|---|---|
| `1d6` | um dado de seis lados: 1 a 6 |
| `2d6` | dois dados de seis somados: 2 a 12 |
| `2d6+6` | dois dados mais 6: 8 a 18 |
| `1d20` | um dado de vinte lados |
| `2d6-1` | dois dados menos 1 |
| `3` | sempre 3, sem rolar |

O jogador sempre mostra os dados rolados, como se rolassem na mesa.

## Testes: passar ou falhar

Uma escolha com `check` em vez de `to` rola dados e manda o leitor para uma de duas páginas:

```gamebook
examples/05-dice/jump-the-gap
```

```json
{ "text": "Saltar (2d6 + Habilidade, 16 ou mais)",
  "check": { "roll": "2d6", "add": "skill", "op": "gte", "vs": 16, "pass": "across", "fail": "fall" } }
```

- `roll`: os dados.
- `add`: um atributo a somar (o valor atual, com bônus de itens) ou um número como `3`. Sem ele, nada é somado.
- `op` e `vs`: `gte` passa quando o total é `vs` ou mais; `lte` passa quando é `vs` ou menos. `vs` pode ser um número ou um atributo.
- `pass` e `fail`: as páginas para onde ir.

Diga ao leitor o que ele vai rolar no texto da escolha, como no exemplo: "(2d6 + Habilidade, 16 ou mais)". Testes aparecem em âmbar, para o leitor distinguir um risco de uma escolha simples. Depois da rolagem, o registro mostra os dados e o total.

## Teste sua Sorte

Em Fighting Fantasy, Testar a Sorte é rolar dois dados e torcer para tirar sua Sorte ou menos, e cada teste gasta um ponto de Sorte, dê no que der. É um teste cujo `vs` é um atributo, com `effects`:

```gamebook
examples/05-dice/test-your-luck
```

```json
"check": { "roll": "2d6", "op": "lte", "vs": "luck",
           "effects": [ { "stat": "luck", "add": -1 } ],
           "pass": "safe", "fail": "hit" }
```

Os `effects` de um teste acontecem depois da rolagem, passe ou falhe, e a rolagem usa os atributos de antes deles. Jogue algumas vezes e veja a Sorte acabar.

## Tabelas de resultado aleatório

Quando há mais de dois resultados, use uma `table`. O dado escolhe o primeiro resultado cujo `upTo` seja pelo menos o valor rolado:

```gamebook
examples/05-dice/search-the-rubble
```

```json
"table": { "roll": "1d6", "outcomes": [
  { "upTo": 2, "to": "nothing" },
  { "upTo": 5, "to": "coins", "effects": [ { "stat": "gold", "add": 3 } ] },
  { "upTo": 6, "to": "gem",   "effects": [ { "give": "gem" } ] }
] }
```

Então 1 ou 2 não acha nada, 3 a 5 acha moedas, 6 acha a gema. `upTo` precisa subir de um resultado para o outro, e o último precisa cobrir a maior rolagem; o verificador avisa se não. Cada resultado pode ter seus próprios `effects`.

### Experimente

- Facilite o salto: mude `vs` para `12`. Ou dificulte, com `"add": 0`.
- Dê ao teste de sorte uma falha mais leve editando a página `hit`.
- Transforme os escombros numa tabela `2d6` com quatro resultados. Lembre: o último `upTo` precisa ser pelo menos 12.

A seguir: as lutas.
