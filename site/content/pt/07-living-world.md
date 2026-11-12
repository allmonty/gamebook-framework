# Um mundo vivo

Bons livros-jogo lembram. O baú que você esvaziou continua vazio, o estalajadeiro reconhece você, a página cita o ouro da sua bolsa e o diário se enche de pistas. Este capítulo trata de memória: coisas que só acontecem uma vez, contagem de visitas, marcadores, condições combinadas, texto que muda, o diário, conquistas, áudio e desfazer.

## Uma vez só

```gamebook
examples/07-living-world/search-once
```

Há dois tipos de "uma vez":

- `"once": true` numa **página** faz os `effects` dela acontecerem só na primeira chegada. O baú paga 5 de ouro uma vez, não importa quantas vezes você o abra. Use em toda coleta e toda cura, para que voltar não vire fazenda.
- `"once": true` numa **escolha** faz a escolha sumir depois de usada (schema 4). O cochilo some depois de uma vez.

## Marcadores, visitas e condições combinadas

Um **marcador** (flag) é um interruptor liga/desliga com o nome que você quiser. Os efeitos `{ "set": "paid" }` e `{ "clear": "paid" }` o ligam e desligam; a condição `{ "flag": "paid" }` o testa. Marcadores não precisam ser declarados; basta escrevê-los.

**Visitas** contam quantas vezes o leitor entrou numa página: `{ "visits": "inn", "gte": 2 }` (schema 4). A página inicial conta como a primeira visita.

Condições se combinam com `all` (todas verdadeiras), `any` (pelo menos uma) e `not` (negação):

```gamebook
examples/07-living-world/the-innkeeper
```

```json
{ "text": "Subir para o quarto", "to": "room",
  "if": { "any": [ { "flag": "paid" }, { "visits": "inn", "gte": 4 } ] },
  "lockedText": "Pague antes, ou vença o estalajadeiro pelo cansaço." }
```

## Texto que muda

O `text` de uma página pode ser uma **lista de partes** (schema 4). Um texto simples sempre aparece; um objeto com `if` só aparece enquanto a condição valer. É assim que o estalajadeiro recebe um estranho na primeira vez e um velho amigo depois:

```json
"text": [
  "A estalagem Chaleira de Cobre, quente e barulhenta.",
  { "if": { "visits": "inn", "eq": 1 }, "text": "O estalajadeiro olha você de cima a baixo: um estranho." },
  { "if": { "visits": "inn", "gte": 2 }, "text": "\"De volta?\", diz o estalajadeiro." }
]
```

### Números no texto

Escreva o id de um atributo entre chaves e o leitor vê o valor atual (schema 4): `{gold}`, `{luck}`. `{luck.max}` é o teto. `{name}` é o nome do herói quando a história pede um (capítulo 4). Funciona no texto das páginas e das escolhas:

```gamebook
examples/07-living-world/gold-counter
```

`{meal.count}` (schema 8) é quantos do item `meal` o leitor carrega: as provisões do capítulo 3 diminuem com ele.

Para mostrar chaves de verdade, escreva duas: `{{` e `}}`.

## O diário e as conquistas

Um `journal` no topo do arquivo lista entradas que o leitor pode desbloquear, cada uma com `title` e `text` (schema 5). O efeito `{ "journal": "letter" }` desbloqueia uma, uma vez só, e o registro avisa. As entradas aparecem no painel do diário, as mais novas primeiro.

**Conquistas** (schema 7) são marcas que o leitor guarda entre partidas: motivo para jogar de novo. Declare em `achievements` e ganhe com `{ "achieve": "scholar" }`. `"hidden": true` mantém a conquista secreta até ser ganha. Elas não mudam nada no jogo.

```gamebook
examples/07-living-world/journal-clues
```

```json
"journal": { "letter": { "title": "A carta do mago", "text": "\"O cofre obedece à palavra BRASA.\"" } },
"achievements": { "scholar": { "title": "Estudioso", "description": "Terminou o escritório." } }
```

## Música e som

Uma página pode definir música e sons (schema 5):

```json
"crypt": { "text": "...", "music": "audio/crypt.ogg", "sound": "audio/door.wav", "choices": [ ... ] }
```

- `sound` toca uma vez quando a página é aberta.
- `music` começa em loop e continua pelas páginas até outra página definir `music`, ou `"music": "stop"` silenciar.

Os caminhos são relativos à pasta da história, como as imagens. Leitores podem desligar o áudio, então nunca esconda algo importante só num som. (Estes exemplos são silenciosos, para o site ficar leve.)

## Desfazer

`"undo": 1` nas regras deixa o leitor voltar essa quantidade de páginas (schema 5). Tudo volta a ser como antes da escolha: atributos, itens, marcadores, visitas. Os dados são rolados de novo se a mesma escolha for feita.

```gamebook
examples/07-living-world/undo-the-trap
```

Desfazer é generoso: desfaz até uma morte. Deixe desligado para um livro clássico e implacável.

## Finais que não são morte

Preso na fronteira, perdido na floresta, de volta para casa: muitas aventuras terminam sem vitória e sem morte. Marque uma página assim com `"ending": "defeat"` (schema 8). O leitor fica sabendo que a aventura acabou, não que morreu.

```gamebook
examples/07-living-world/captured
```

Dois dos três finais são derrotas, e o herói está vivo nos dois. Vida em 0 continua sendo morte, diga a página o que disser.

### Experimente

- Na estalagem, mude `"gte": 4` para `"gte": 2`: o estalajadeiro cede mais cedo.
- No poço, adicione a parte `{ "if": { "stat": "luck", "gte": 12 }, "text": "Você se sente muito sortudo." }`.
- No escritório, torne a conquista Cartógrafo visível tirando `"hidden": true`.
- Na fronteira, troque o `"defeat"` da cela por `"death"` e veja o que o leitor fica sabendo.

A seguir: garantir que um livro longo não tem links quebrados, e compartilhá-lo.
