# Páginas e escolhas

Um livro-jogo é uma teia de páginas ligadas por escolhas. Este capítulo mostra como desenhar essa teia: como escrever uma página, como as escolhas levam adiante, como a história termina e como manter uma porta fechada até o leitor merecer abri-la.

## Caminhos e finais

```gamebook
examples/02-pages-and-choices/two-doors
```

Jogue duas vezes, uma por cada porta. Depois abra **Editar JSON** e veja como é feito:

- **Quatro páginas** em `nodes`: `hall`, `red`, `blue` e `roof`. Os nomes são escolha sua; use letras, números, `-` e `_`. O leitor nunca os vê.
- **Dois jeitos de terminar.** `"ending": "death"` em `red`, `"ending": "victory"` em `roof`. Uma história pode ter quantos finais de cada tipo você quiser.
- **Voltar é só mais uma escolha.** `blue` oferece "Voltar ao salão", que aponta (`to`) para a página `hall`. Voltas e ciclos são permitidos.

Uma página precisa de exatamente um jeito de seguir: uma lista de `choices`, um `ending` ou uma luta. Uma página sem nenhum deles é um erro, porque o leitor ficaria preso.

### Parágrafos

Dentro de `text`, escreva `\n\n` (barra invertida e n, duas vezes) para começar um parágrafo novo. A página do salão usa isso. Em JSON, não dá para quebrar a linha de verdade dentro das aspas.

### Imagens

Uma página pode mostrar uma imagem acima do texto:

```json
"hall": { "text": "...", "image": "images/hall.webp", "choices": [ ... ] }
```

O caminho é relativo à pasta da história, então `images/hall.webp` fica ao lado de `story.pt.json`. `.webp`, `.png` e `.jpg` funcionam. O validador de linha de comando avisa se o arquivo não existir. O corredor do primeiro exemplo deste capítulo tem uma.

### Descreva suas imagens

Alguns leitores não conseguem ver a imagem: leem com um leitor de tela, ou a imagem não carregou. Dê a imagem a eles em palavras com `imageAlt`:

```json
"hall": {
  "text": "...",
  "image": "images/hall.png",
  "imageAlt": "Um corredor escuro coberto de espelhos. No fundo, duas portas: uma brilha em vermelho, a outra em azul.",
  "choices": [ ... ]
}
```

Diga o que o leitor notaria, em uma frase; não precisa começar com "Uma imagem de". O jogo passa esse texto ao leitor de tela. Sem ele, a imagem conta como decoração e é pulada. `imageAlt` só vai ao lado de uma `image`, e a imagem de um item recebe uma do mesmo jeito. Cada tradução escreve a sua. Abra **Editar JSON** no exemplo das duas portas para ver a do corredor, e mude-a.

## Escolhas que esperam

Algumas escolhas só devem funcionar depois que o leitor fez alguma coisa. Dê à escolha um `if` com uma **condição**:

```gamebook
examples/02-pages-and-choices/the-terminal
```

Aqui a porta do cofre fica **trancada** até você ler o terminal. `{ "visited": "terminal" }` é verdadeiro quando o leitor já passou pela página `terminal`.

Uma escolha trancada aparece desativada, com o motivo embaixo. Sem nada a mais, o aplicativo escreve o motivo a partir da condição ("Precisa: ..."); com `lockedText` você mesmo escreve, o que fica melhor para visitas e segredos: "Trancada. Talvez o terminal saiba o código."

A terceira escolha, a escotilha de manutenção, tem `"hideIfLocked": true`: enquanto a condição não vale, o leitor nem a vê. Use para segredos; use escolhas desativadas quando quiser que o leitor saiba que algo é possível.

### Experimente

1. Mude o `hideIfLocked` da escotilha para `false`. Agora o segredo aparece, mas trancado.
2. Apague a linha `lockedText` da porta do cofre (e a vírgula antes dela) e veja o motivo que o aplicativo escreve sozinho.
3. Aponte uma escolha para uma página que não existe, como `"to": "nowhere"`. O verificador mostra a escolha exata: é assim que você vai achar erros de digitação em livros longos.

## De volta para onde você veio

Livros-jogo impressos dizem "visite o mascate e depois volte à seção de onde veio". Uma página pode servir a muitas outras:

```gamebook
examples/02-pages-and-choices/the-pedlar
```

- `"call": true` numa escolha lembra a página onde você está e segue para o destino como sempre. As três estradas chamam o mascate assim.
- `"return": true` no lugar de `to` leva de volta à última página lembrada: "Despedir-se" leva você de volta à sua estrada. Um retorno sem nada lembrado fica trancado, e o verificador avisa quando isso pode acontecer.
- O `win` (ou o `flee`) de uma luta pode ser `{ "return": true }`: o lobo do vau aparece numa tabela de dados cuja escolha chama, e vencê-lo põe você de volta no vau.
- Voltar **entra** na página de novo: os efeitos dela valem, a não ser que a página seja `once`, e a visita conta. Chamadas podem se aninhar, até 16 níveis.

### Experimente

1. Tire o `"call": true` do "Chamar o mascate" da estrada do norte. O verificador avisa, e nessa estrada "Despedir-se" fica trancado.

## O que você aprendeu

| Campo | Em | Significado |
|---|---|---|
| `text` | página, escolha | O que o leitor vê. `\n\n` começa um parágrafo. |
| `image` | página | Uma imagem acima do texto. |
| `imageAlt` | página, item | O que a imagem mostra, para leitores que não conseguem vê-la. |
| `choices` | página | Os botões. |
| `to` | escolha | A página para onde a escolha leva. |
| `ending` | página | `"victory"` ou `"death"`: o jogo acabou. |
| `if` | escolha | Uma condição; enquanto for falsa, a escolha fica trancada. |
| `lockedText` | escolha | Suas palavras para explicar por que está trancada. |
| `hideIfLocked` | escolha | Esconde a escolha enquanto estiver trancada. |
| `call` | escolha | Lembra esta página para um retorno depois. |
| `return` | escolha, `win` ou `flee` de uma luta | Volta à última página lembrada. |

`visited` é a primeira de muitas condições. A seguir, o leitor começa a carregar coisas.
