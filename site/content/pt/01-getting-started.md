# Primeiros passos

Um livro-jogo é uma história que o leitor joga: lê uma página, escolhe o que fazer e vai para a página que a escolha indica. Com o Gamebook Framework o livro inteiro cabe em **um arquivo de texto**. Você escreve as páginas e as regras; qualquer aplicativo jogador lê o arquivo e roda a aventura.

Você não precisa programar. Precisa de um editor de texto, uns dez minutos e as quatro regras abaixo.

## Experimente primeiro

Abaixo está um livro-jogo completo, com duas páginas. Toque numa escolha para jogar.

```gamebook
examples/01-getting-started/hello-world
```

Agora abra a aba **Editar JSON**. Aquele texto *é* o livro-jogo. Mude as palavras depois de `"title":`, espere um instante e volte para **Jogar**: a mudança já está no jogo. Todo exemplo deste tutorial funciona assim, então experimente à vontade; **Restaurar** traz o original de volta.

## JSON em quatro regras

O arquivo é escrito em JSON, um jeito comum de escrever dados que pessoas e programas conseguem ler. Você só precisa de quatro regras:

1. **Texto vai entre aspas duplas**: `"Atravessar o portão"`. Aspas retas `"`, não as curvas.
2. **Chaves `{ }` guardam campos com nome**, escritos `"nome": valor`. **Colchetes `[ ]` guardam listas.**
3. **Vírgulas separam os itens**, nunca depois do último.
4. **Números e `true` / `false` vão sem aspas**: `"schema": 1`, `"once": true`.

Se você quebrar uma regra, o verificador embaixo do editor mostra onde. Teste: apague uma vírgula no exemplo e leia a mensagem. Depois toque em Restaurar.

## O que tem no arquivo

Toda história começa com os mesmos poucos campos:

| Campo | O que é |
|---|---|
| `schema` | A versão do formato que a história usa. Comece com `1`; os próximos capítulos dizem quando um recurso pede um número maior. |
| `id` | Um nome curto para a história, com letras minúsculas, números e hífens: `hello-world`. |
| `lang` | O idioma deste arquivo: `en`, `pt`... |
| `title` | O título que os leitores veem. |
| `rules` | As regras do jogo. `"preset": "fighting-fantasy"` dá a você a clássica Habilidade, Energia e Sorte. O capítulo 4 explica as regras em detalhe. |
| `start` | O id da primeira página. |
| `nodes` | As páginas. Cada página tem um id (`gate`, `city`) e o seu conteúdo. |

Em português, o exemplo também troca os nomes dos atributos em `rules.stats` (`"label": "Habilidade"`), porque os presets vêm com nomes em inglês. O capítulo 4 mostra isso com calma.

Uma página (um *node*, ou nó) tem `text` e exatamente um jeito de seguir:

- `choices`: uma lista de botões, cada um com o `text` a mostrar e a página para onde vai (`to`);
- um final, `ending`: `"victory"` (vitória) ou `"death"` (morte);
- ou uma luta (capítulo 6).

Os ids e os nomes dos campos ficam sempre em inglês; só o texto que o leitor vê muda de idioma.

### Exercício

Adicione uma terceira página. Na aba Editar JSON, mude a página `city` para que ela ofereça uma escolha em vez de terminar:

```json
"city": {
  "text": "Luzes, barulho e mil histórias.",
  "choices": [ { "text": "Procurar uma estalagem", "to": "inn" } ]
},
"inn": { "text": "Uma cama quente. Sua história começa amanhã.", "ending": "victory" }
```

Cuidado com a vírgula entre `city` e `inn`. Se o verificador reclamar, leia para onde ele aponta.

## Escrevendo no seu computador

Quando a história crescer, escreva num arquivo:

1. Instale um editor de código como o [Visual Studio Code](https://code.visualstudio.com/) (gratuito). Ele colore o JSON e mostra erros enquanto você digita.
2. Crie uma pasta para o jogo e salve a história nela como `story.pt.json` (`story.en.json` para inglês, e assim por diante).
3. Adicione esta linha logo depois da `{` inicial para ganhar sugestões e verificação de cada campo enquanto digita:
   ```json
   "$schema": "https://raw.githubusercontent.com/allmonty/gamebook-framework/main/spec/story.schema.json",
   ```
4. Para jogar, abra o [playground](../play.html), toque em **Abrir arquivo** e escolha sua história.

A seguir você vai dar decisões de verdade ao leitor: várias escolhas, becos sem saída e mais de um jeito de terminar.
