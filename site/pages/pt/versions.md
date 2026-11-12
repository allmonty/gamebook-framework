# Versões do formato

Toda história diz para qual versão do formato foi escrita, perto do começo do arquivo: `"schema": 1`. Esta página diz o que esse número significa e o que cada versão deixa você escrever.

## Como as versões funcionam

- **Versões só acrescentam.** Uma versão nova traz coisas novas para escrever. Nada que funciona numa versão deixa de funcionar numa versão depois: uma história só precisa dizer o número novo para usar as novidades.
- **Diga a versão que você usa.** Uma história que usa algo que uma versão trouxe precisa dizer essa versão (ou uma depois) em `"schema"`. O verificador avisa quando o número está baixo demais, e em qual linha.
- **Um aplicativo só joga o que conhece.** Um aplicativo que não conhece a versão de uma história a recusa com uma mensagem, em vez de jogá-la pela metade. Atualize o aplicativo para jogar a história mais nova.
- **As versões novas aparecem aqui**, da mais nova para a mais antiga, com o que deixam você escrever e onde o tutorial ensina. Quem escreve motores encontra o registro exato no [changelog](https://github.com/allmonty/gamebook-framework/blob/main/spec/CHANGELOG.md) (em inglês).

## Versão 1

A primeira versão, com tudo o que o tutorial ensina. Escreva `"schema": 1`.

- **Páginas e escolhas** ([capítulo 2](tutorial/02-pages-and-choices.html)): páginas ligadas por escolhas; finais de vitória, derrota e morte; imagens, com descrições para quem não consegue vê-las; escolhas trancadas por uma condição, com o seu próprio motivo; uma página que manda o leitor de volta para onde veio.
- **Itens** ([capítulo 3](tutorial/03-items.html)): chaves e portas trancadas; itens que o leitor usa, na história ou numa luta; itens que melhoram o herói; uma mochila com espaço limitado, recipientes e ofertas; ladrões e enchentes; coisas que vêm em quantidade, com um limite.
- **Atributos e o herói** ([capítulo 4](tutorial/04-stats-and-hero.html)): regras prontas ou seus próprios atributos; tetos, limites e atributos que ficam abaixo de zero; preços que apontam para outros atributos; bônus que dependem de uma condição; a criação do herói, com nome e escolhas.
- **Dados** ([capítulo 5](tutorial/05-dice.html)): testes de dados, Testar a Sorte, tabelas de resultados aleatórios.
- **Combate** ([capítulo 6](tutorial/06-combat.html)): lutas disputadas e o jeito d20; vários inimigos de uma vez, armadura e sorte; tabelas de resultados e duelos; lutas que acabam antes; fugir que custa uma rodada.
- **Um mundo vivo** ([capítulo 7](tutorial/07-living-world.html)): escolhas e páginas de uma vez só; marcadores e visitas; texto que muda, e números no texto; o diário e as conquistas; música e som; desfazer; regras em toda página, para cura, veneno e feitiços que passam.
- **Verificar e publicar** ([capítulo 8](tutorial/08-check-and-publish.html)): títulos de página, notas, capítulos e rascunhos; o verificador; traduções; um arquivo só para compartilhar um jogo.
