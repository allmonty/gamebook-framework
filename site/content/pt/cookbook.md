# Livro de receitas

Receitas prontas para cenas que todo livro-jogo precisa. Cada uma é uma história pequena e completa: jogue, abra Editar JSON e copie as partes que quiser para o seu livro. Os capítulos que explicam cada peça estão nos links.

## O baú trancado

*Um baú que abre com uma chave ou com uma gazua de sorte, e só paga uma vez.*

```gamebook
examples/cookbook/locked-chest
```

- Duas escolhas levam à mesma página `open`: uma precisa da chave (`"if": { "has": "key" }`), a outra é um teste de habilidade ([capítulo 5](05-dice.md)).
- `"once": true` na página `open` faz o ouro ser dado só da primeira vez ([capítulo 7](07-living-world.md)).
- A chave é gasta com `take` quando usada.

## O mercador errante

*Comprar e vender com preço, mostrando a bolsa ao leitor.*

```gamebook
examples/cookbook/wandering-merchant
```

- Comprar precisa de `{ "stat": "gold", "gte": 5 }` e paga com `{ "stat": "gold", "add": -5 }`.
- Vender precisa do item e devolve ouro.
- `{gold}` no texto mantém a bolsa em dia ([capítulo 7](07-living-world.md)). Para muitas lojas com preços diferentes, guarde o preço num atributo ([capítulo 4](04-stats-and-hero.md)).

## A passagem secreta

*Um segredo que só heróis atentos veem de cara, e que os outros percebem na terceira olhada.*

```gamebook
examples/cookbook/hidden-passage
```

- A escolha secreta tem `"hideIfLocked": true`, então fica invisível até a condição valer ([capítulo 2](02-pages-and-choices.md)).
- A condição é `any` entre Habilidade 11 ou mais e uma terceira visita à biblioteca ([capítulo 7](07-living-world.md)).
- Uma parte do texto dá a pista a partir da segunda visita.

## A armadilha de veneno

*Dano que continua em toda página até ser curado.*

```gamebook
examples/cookbook/poison-trap
```

- Falhar no teste liga o marcador `poisoned` e oferece um antídoto cujo `use` o desliga ([capítulo 3](03-items.md)).
- Cada página seguinte tem duas versões de "Seguir", ambas com `hideIfLocked`: uma para quem está bem (`not` envenenado), outra para o envenenado, que custa 2 de Energia. O leitor só vê uma.
- Uma parte do texto lembra o leitor envenenado do porquê da dor.

## A luta com o chefe

*Um chefe com um guarda, um pedido de piedade e uma segunda fase mais difícil.*

```gamebook
examples/cookbook/boss-fight
```

- Fase um: o chefe e o guarda atacam juntos (`simultaneous`), e o chefe tem `armor` ([capítulo 6](06-combat.md)).
- Vencer leva a uma página normal com uma escolha moral, não direto à vitória.
- Acabar com ele começa uma segunda luta numa página própria, com um inimigo mais forte e sem fuga.
- Fugir da fase um é permitido, mas leva a um final de morte: o preço de fugir de um chefe.

Tem uma receita para compartilhar? O formato é aberto: escreva, valide e envie.
