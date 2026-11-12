# Modelos de jogo

Oito livros-jogo completos para jogar aqui e depois transformar no seu. Cada um é curto, original e feito para ser copiado: mostra um jeito de construir um livro, com os campos que esse jeito pede.

Para cada um:

- **Jogue** aqui mesmo na página.
- **Veja** como ele é escrito na aba **Editar JSON**, e mude: o jogo recomeça com a sua versão.
- **Use**: aperte **Baixar** na aba Editar JSON para salvar o arquivo, ou copie a pasta inteira do GitHub, em inglês e português.

O [tutorial](tutorial/index.html) explica cada campo que você vai encontrar.

## Em branco

O menor jogo válido: três páginas e um final, com o preset Fighting Fantasy. Comece por aqui quando já souber o que quer escrever.

```gamebook
../starters/blank/story
```

O que ele mostra:

- uma página com escolha, uma página no meio, um final
- os campos que toda história precisa, e nada mais

A pasta para copiar: [`starters/blank`](https://github.com/allmonty/gamebook-framework/tree/main/starters/blank).

## A Mina de Sal

O formato clássico: Habilidade, Energia e Sorte, uma luta, um Teste de Sorte, provisões que você come da mochila e uma porta que pede uma chave.

```gamebook
../starters/fighting-fantasy/story
```

O que ele mostra:

- o preset `fighting-fantasy` como ele vem
- uma luta oposta e o Teste de Sorte
- um item contável (`stack`) que você usa
- os três finais: vitória, morte e derrota

A pasta para copiar: [`starters/fighting-fantasy`](https://github.com/allmonty/gamebook-framework/tree/main/starters/fighting-fantasy).

## O Arquivo à Noite

Sem preset: a história define seus dois atributos, diz qual deles é a vida e como as lutas funcionam.

```gamebook
../starters/custom-rules/story
```

O que ele mostra:

- `rules` escrito por inteiro: `stats`, `health`, `combat`
- um teste de dados que soma um atributo
- uma luta com as suas próprias regras

A pasta para copiar: [`starters/custom-rules`](https://github.com/allmonty/gamebook-framework/tree/main/starters/custom-rules).

## A Estrada das Cinzas

As lutas são lidas numa tabela de resultados, em vez de dados contra dados. Você escolhe duas artes no começo, carrega uma mochila de oito espaços e precisa comer.

```gamebook
../starters/results-table/story
```

O que ele mostra:

- combate com `"mode": "table"` e a sua tabela
- escolhas na criação do herói, cada uma ligando um marcador
- uma mochila com `capacity`, um recipiente, refeições contáveis com `max`
- um bônus que depende de uma condição (desarmado, ou a espada com a arte certa)
- cura em toda página sem luta (`everyPage`, `calm`)
- fuga que custa uma rodada

A pasta para copiar: [`starters/results-table`](https://github.com/allmonty/gamebook-framework/tree/main/starters/results-table).

## O Testamento do Relojoeiro

Um mistério sem nenhuma luta. As perícias vão de 30 a 75 e você rola 1d100 abaixo delas; as pistas vão para o diário até você poder apontar o falsário.

```gamebook
../starters/percentile-mystery/story
```

O que ele mostra:

- uma história sem `combat` nas regras
- testes de `1d100` com `lte` contra um atributo, cada um permitido uma vez
- o diário como quadro de pistas
- marcadores que abrem o que as pessoas dizem, e texto que muda com o que você sabe
- duas derrotas e uma vitória, e nenhuma morte

A pasta para copiar: [`starters/percentile-mystery`](https://github.com/allmonty/gamebook-framework/tree/main/starters/percentile-mystery).

## Dia de Feira em Três Pontes

Uma cidade para onde você volta. Uma loja é alcançada de dois lugares e devolve você para onde veio; você compra, vende e troca o que carrega.

```gamebook
../starters/hub-and-shop/story
```

O que ele mostra:

- `call` e `return`: uma loja, muitas entradas
- um preço guardado num atributo escondido, e um único "Comprar" que paga o que ele disser
- uma mochila de três com `"pickup": "choose"`: a quarta coisa é uma troca
- texto que muda com `visits`, e um serviço que só dá para fazer uma vez (`once`)
- um jeito de vencer que não precisa de item, porque um item oferecido pode ser deixado

A pasta para copiar: [`starters/hub-and-shop`](https://github.com/allmonty/gamebook-framework/tree/main/starters/hub-and-shop).

## A Capela Submersa

Uma masmorra pequena com o preset d20-lite, alterado em vez de usado inteiro: dois inimigos de uma vez, um chefe de armadura e a água subindo.

```gamebook
../starters/d20-dungeon/story
```

O que ele mostra:

- um preset com um atributo alterado (`min` abaixo de zero) e um novo
- uma `table` aleatória, um item com `bonus` e um amaldiçoado
- itens usáveis: um grátis na luta, um que custa a rodada
- uma luta `simultaneous`, `armor`, um inimigo com `damage` próprio
- uma luta que acaba depois de seis `rounds`, vencida ou não

A pasta para copiar: [`starters/d20-dungeon`](https://github.com/allmonty/gamebook-framework/tree/main/starters/d20-dungeon).

## O Ano do Farol

O esqueleto de um livro longo: estrutura, não regras. Copie quando for escrever duzentas páginas.

```gamebook
../starters/long-book/story
```

O que ele mostra:

- `chapters`, e um `chapter` em cada página
- títulos de página que o leitor vê (`showTitles`) e uma `note` que só você vê
- uma entrada de diário e duas conquistas, uma `hidden`
- `undo`, para a escolha difícil poder ser feita dos dois jeitos

A pasta para copiar: [`starters/long-book`](https://github.com/allmonty/gamebook-framework/tree/main/starters/long-book).

## Como fazer um deles ser seu

Copie a pasta, troque o nome dela e mude o `id` em cada arquivo de idioma para o mesmo nome novo. Depois confira a história enquanto escreve: o [capítulo 8](tutorial/08-check-and-publish.html) mostra o verificador e as ferramentas.
