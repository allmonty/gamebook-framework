# Verificar e publicar

Um livro-jogo de verdade tem centenas de páginas. Em algum lugar uma escolha aponta para uma página que você renomeou, um item é exigido mas nunca dado, um marcador é testado mas nunca ligado. Este capítulo mostra como o framework acha esses erros para você, como organizar um livro longo, como traduzi-lo e como compartilhá-lo.

## O verificador que você já está usando

Todo exemplo deste tutorial roda o mesmo validador das ferramentas de linha de comando. Ele aponta dois tipos de problema:

- **Erros** deixam a história injogável: uma escolha para uma página que não existe, um campo faltando, um nome de campo com erro de digitação, dados inválidos. A história não roda até serem corrigidos.
- **Avisos** apontam o que provavelmente é um engano numa história que ainda funciona. Cada um tem um código:

| Código | Quando |
|---|---|
| `unreachable` | nenhum caminho leva do início até a página |
| `no-victory` | nenhum final de vitória pode ser alcançado |
| `required-never-given` | uma escolha precisa de um item que nada entrega |
| `taken-never-given` / `usable-never-given` | um item é tirado ou usável, mas nunca entregue |
| `flag-never-set` / `flag-never-checked` | um marcador é testado mas nunca ligado, ou ligado mas nunca testado |
| `journal-never-unlocked` / `never-earned` | uma entrada de diário ou conquista que nada desbloqueia |
| `return-without-call` | uma página tem um `return`, mas dá para chegar nela sem ter página para onde voltar |
| `capacity-without-pack` | um recipiente numa história cuja mochila não tem limite |
| `draft` | uma página ainda marcada como rascunho |

Toda mensagem diz o lugar no arquivo, como `nodes.door.choices[1].to`: a página `door`, a segunda escolha dela (contando do 0), o campo `to`.

### Experimente

Use o exemplo abaixo. Em Editar JSON:

1. Adicione uma página sem nenhum link para ela: `"attic": { "text": "Poeira.", "ending": "death" },`. Aparece o aviso `unreachable`.
2. Adicione `"if": { "flag": "brave" }` a uma escolha. Aparece `flag-never-set`.
3. Renomeie a página `road` para `path`, mas não a escolha que leva até ela. Isso é um erro, e o jogo para até ser corrigido.

## Organizando um livro longo

Alguns campos são só para autores. Nenhum muda como a história é jogada, exceto `showTitles`:

```gamebook
examples/08-check-and-publish/tidy-book
```

| Campo | Onde | Significado |
|---|---|---|
| `title` | página | um nome curto para a página, mostrado pelas ferramentas e, com `showTitles`, aos leitores como título da página |
| `showTitles` | topo | `true` mostra os títulos das páginas aos leitores |
| `note` | página | uma nota para você; leitores nunca a veem |
| `chapters` | topo | `{ "act1": { "title": "Ato 1: A vila" } }`, na ordem de leitura |
| `chapter` | página | a qual capítulo a página pertence |
| `draft` | página | `true` marca uma página inacabada: ela pode ficar sem texto e sem saída por enquanto, e mostra um aviso até você terminá-la |

## As ferramentas de linha de comando

Quando a história mora em arquivos, as ferramentas do motor de referência a verificam e inspecionam. Elas precisam do [Dart](https://dart.dev/get-dart) instalado e de uma cópia deste repositório; rode-as a partir de `engines/dart`:

```
dart run gamebook_engine:validate_story caminho/do/meu-jogo --strict
dart run gamebook_engine:story_graph caminho/do/story.pt.json --mermaid
dart run gamebook_engine:simulate_story caminho/do/story.pt.json --games 2000
```

- **validate_story** confere cada `story.<idioma>.json` de uma pasta e compara as traduções. `--strict` também falha com avisos. `--llm` escreve os problemas como uma mensagem para colar de volta num assistente de IA que escreveu a história.
- **story_graph** imprime a história como um mapa: Graphviz DOT por padrão, ou Mermaid, que o GitHub e muitos editores desenham para você.
- **simulate_story** joga a história milhares de vezes ao acaso e relata becos sem saída, loops e finais que ninguém alcança.

## Traduções

Cada idioma é um arquivo próprio, lado a lado: `story.en.json`, `story.pt.json`. Eles compartilham o mesmo `id` e precisam ter os mesmos ids de páginas, itens, atributos, marcadores e capítulos, o mesmo número de escolhas em cada página, na mesma ordem, e o mesmo número de partes de texto. Só as palavras mudam. O validador compara cada tradução com o primeiro idioma e avisa qualquer outra diferença: um id que falta (`translation-missing`), outro número de escolhas (`translation-choices`) ou qualquer coisa que não seja texto, como para onde uma escolha leva ou o que um item faz (`translation-structure`). O jeito fácil de não errar é traduzir uma cópia do primeiro arquivo. Todo exemplo deste site existe em inglês e português, conferido assim.

Lembre de traduzir os nomes dos atributos em `rules.stats` quando usar um preset (capítulo 4).

## Compartilhando seu jogo

- **Um pacote `.gamebook`** é um zip da pasta do jogo: os arquivos da história e as pastas `images/` e `audio/` que eles usam. Crie um com `dart run gamebook_engine:pack_game caminho/do/meu-jogo`; aplicativos que aceitam pacotes importam esse único arquivo.
- **Vindo do Twine**: `dart run gamebook_engine:import_twine story.twee pasta-de-saida` converte uma história do Twine (`.twee` ou `.html` publicado) e relata o que não conseguiu converter.
- **Com um assistente de IA**: [o kit para LLMs](../../llm-kit.md) (`spec/llm-kit.md` no repositório) é um arquivo que ensina o formato a um chatbot. Entregue-o ao assistente junto com o seu pedido; depois rode o validador com `--llm` e cole a resposta de volta até a história ficar limpa.
- **Em qualquer plataforma**: o formato é dado puro, então motores podem existir em qualquer linguagem. A [suíte de conformidade](https://github.com/allmonty/gamebook-framework/tree/main/conformance) tem casos de teste que garantem que todo motor joga cada história do mesmo jeito.

## Para onde ir agora

- Os [modelos de jogo](../starters.html) são oito livros-jogo completos para jogar, ler e copiar.
- O [livro de receitas](cookbook.md) tem receitas prontas: um baú trancado, um mercador, uma passagem secreta, uma armadilha de veneno, uma luta de chefe.
- A [especificação completa](https://github.com/allmonty/gamebook-framework/blob/main/spec/framework.md) lista cada campo com precisão.
- O [playground](../play.html) está pronto para sua primeira história de verdade.
