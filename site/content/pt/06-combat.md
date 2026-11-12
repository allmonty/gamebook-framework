# Combate

Uma luta é uma página própria. Em vez de escolhas, ela tem `combat`: os inimigos, para onde ir ao vencer e, se você permitir, para onde fugir. O leitor luta rodada a rodada com o botão Atacar, e as regras decidem como cada rodada acontece.

## Uma luta, rodada a rodada

```gamebook
examples/06-combat/goblin-guard
```

```json
"fight": {
  "text": "O goblin rosna e avança.",
  "combat": {
    "enemies": [ { "name": "Guarda goblin", "attack": 6, "health": 5 } ],
    "win": "won",
    "flee": "fled"
  }
}
```

- `enemies`: cada um com `name`, um valor de ataque (`attack`) e vida (`health`). Vários inimigos são enfrentados um depois do outro, na ordem.
- `win`: a página para onde ir quando o último inimigo cai.
- `flee` (opcional): a página para onde fugir. Fugir não tem punição automática; coloque nos `effects` daquela página, como o exemplo faz com -2 de Energia. Sem `flee`, não há fuga.

Com as regras de Fighting Fantasy cada rodada é **oposta**: você rola 2d6 + Habilidade, o inimigo rola 2d6 + `attack`, e o menor total perde 2 de vida. Empate não fere ninguém. Se a sua vida chegar a 0, a história termina em morte.

O tônico mostra **itens nas lutas**: o `use` dele tem `"when": ["story", "combat"]`, então o botão Usar funciona no meio da luta. Usar custa o seu ataque naquela rodada, e o inimigo acerta você de graça. Coloque `"combatCost": "free"` num item que não deve custar.

## Contra defesa: o jeito d20

Com as regras `d20-lite` cada rodada é **contra defesa**: você rola 1d20 + Força e acerta se alcançar a defesa (`defense`) do inimigo; depois o inimigo rola 1d20 + `attack` contra 10 + sua Agilidade. Acertos causam dados de dano, 1d6 por padrão.

```gamebook
examples/06-combat/d20-skirmish
```

```json
"enemies": [ { "name": "Bandido da ferrugem", "attack": 2, "defense": 11, "health": 6, "damage": "1d4" } ]
```

`defense` é obrigatório neste modo. `damage` num inimigo troca o dano das regras só para ele.

## Vários inimigos, armadura e sorte

```gamebook
examples/06-combat/golem-and-rat
```

- `"simultaneous": true` na luta: todo inimigo vivo ataca em toda rodada, e o leitor **escolhe um alvo** a cada rodada (schema 5).
- `"armor": 1` num inimigo: seus golpes causam 1 a menos nele, nunca menos que 0.
- `"luck": { "stat": "luck" }` no `combat` das regras liga o **Teste de Sorte nas lutas**: depois de uma rodada em que alguém se feriu, o leitor pode rolar 2d6 contra a Sorte. Com sorte, seu ferimento no inimigo cresce 2 ou o ferimento que você levou diminui 1; sem sorte, o contrário. A Sorte cai 1 de qualquer jeito.

```json
"rules": { "preset": "fighting-fantasy", "combat": { "luck": { "stat": "luck" } } }
```

## Tabelas de resultados e duelos

Os livros do Lobo Solitário resolvem lutas com uma **tabela de resultados** em vez de dados contra dados. A diferença entre o seu atributo de luta e o do inimigo (a *razão de combate*) escolhe uma linha; uma rolagem de `1d10-1` (0 a 9) escolhe uma coluna; cada célula diz quanto os dois lados perdem na rodada.

Você pode fazer uma história inteira lutar assim com `"mode": "table"` no `combat` das regras, ou, como aqui, manter as lutas normais e marcar uma luta especial como duelo (`duel`):

```gamebook
examples/06-combat/duel-table
```

```json
"rules": { "preset": "fighting-fantasy",
  "combat": { "roll": "1d10-1", "table": [
    { "upTo": -3, "results": [[0,4],[0,3],[1,3],[1,2],[2,2],[2,2],[3,1],[3,1],[4,0],[4,0]] },
    { "upTo": 3,  "results": [[1,2],[2,2],[2,1],[3,1],[3,1],[4,1],[4,0],[5,0],[5,0],[6,0]] },
    {             "results": [[3,1],[4,1],[5,0],[5,0],[6,0],[7,0],[8,0],[9,0],[10,0],[99,0]] }
  ] } }
```

Cada par é `[inimigo perde, você perde]`. Uma linha cobre toda razão até o seu `upTo`; a última não tem e pega tudo acima. Cada linha precisa de um par para cada rolagem possível, dez aqui. A luta no salão tem `"duel": true`; o drone de treino no pátio ainda luta do jeito normal.

## Lutas que acabam antes

Livros-jogo adoram "se a criatura ferir você, vá para 55" e "se você não vencer em três rodadas, vá para 120". Dois campos em `combat` dizem isso (schema 8):

```gamebook
examples/06-combat/poison-sting
```

```json
"combat": {
  "enemies": [ { "name": "Escorpião gigante", "attack": 7, "health": 6 } ],
  "win": "won",
  "wounded": "stung",
  "rounds": { "after": 3, "to": "gone" }
}
```

- `wounded`: na primeira vez que o escorpião ferir você, e você ainda estiver vivo, a luta para e `stung` vem em seguida.
- `rounds`: jogadas 3 rodadas sem vencedor, a luta para e `gone` vem em seguida. "Vença em três rodadas" se escreve do mesmo jeito.

Depois de cada rodada a ordem é: morte, depois a vitória, depois um ferimento, depois o limite de rodadas. Um item que custa a rodada conta como rodada, e o golpe livre do inimigo como ferimento. Para fugir pagando um preço você não precisa de nada novo: é o `flee` com um efeito na página para onde você foge, como mostra o guarda goblin.

### Fugir custa uma rodada

Em Lobo Solitário a fuga é diferente: na rodada em que você vira para fugir, só o inimigo pode ferir você, então fugir pode matar. Ponha `"fleeCost": "round"` ao lado de `flee` (schema 8):

```gamebook
examples/06-combat/the-evasion
```

Aperte Fugir (o botão avisa que custa uma rodada): o troll golpeia uma vez, exatamente como quando você usa um item que custa a rodada, e só então você chega à página da fuga. Se esse golpe levar sua última Energia, você nunca chega lá. O golpe não conta como ferimento para `wounded` nem como rodada para `rounds`.

### Experimente

- Dê ao goblin `"health": 12` e veja a luta crescer. Tire o `flee` e o botão Fugir some.
- Dê ao golem `"armor": 2`: agora só golpes de sorte o ferem.
- Tire o `"duel": true` do Campeão e enfrente-o com dados.
- Tire o `wounded` do escorpião: a ferroada agora é só um ferimento, e a luta continua.
- Troque o `fleeCost` do troll por `"free"`: fugir volta a ser seguro.

A seguir: fazer o mundo lembrar do que o leitor fez.
