import 'dart:io';

import 'package:gamebook_engine/story.dart';
import 'package:gamebook_engine/text.dart';
import 'package:gamebook_engine/twine.dart';
import 'package:test/test.dart';

import '../bin/import_twine.dart';

final twee = File('test/fixtures/lighthouse.twee').readAsStringSync();

Map<String, Object?> node(TwineImport r, String id) =>
    (r.story['nodes']! as Map<String, Object?>)[id]! as Map<String, Object?>;

void main() {
  test('braces in Twine text stay literal, and the id has no underscore', () {
    final r = importTwine(
      ':: StoryTitle\nMy_Story\n\n'
      ':: Start\nA jar. <<set \$x to {a: 1}>>\n[[Open {it}->End]]\n\n'
      ':: End [victory]\nDone.\n',
    );
    final story = Story.fromJson(r.story);

    expect(story.id, 'my-story');
    expect(
      renderTemplate(story.nodes['Start']!.text, (_) => null),
      contains('{a: 1}'),
    );
    expect(
      renderTemplate(story.nodes['Start']!.choices.single.text, (_) => null),
      'Open {it}',
    );
  });

  test('Twee passages become pages, links choices, the rest is reported', () {
    final r = importTwine(twee, lang: 'pt');
    final story = Story.fromJson(r.story);

    expect(story.title, 'The Lighthouse');
    expect(story.lang, 'pt');
    expect(story.start, 'Shore');
    // Special passages and stylesheets are not pages.
    expect(story.nodes.keys, [
      'Shore',
      'Stairs',
      'Lamp-room',
      'Morning',
      'Keeper',
    ]);
    expect(story.nodes['Lamp-room']!.title, 'Lamp room');

    // [[text->target]] and [[text|target]], on lines of their own.
    expect(node(r, 'Shore'), {
      'title': 'Shore',
      'text': 'Waves break on the rocks. The lighthouse is dark tonight.',
      'choices': [
        {'text': 'Climb to the light', 'to': 'Stairs'},
        {'text': 'Wait for morning', 'to': 'Morning'},
      ],
    });
    // A link in a sentence keeps its words.
    expect(
      node(r, 'Stairs')['text'],
      endsWith('You can open the door or go back down.'),
    );
    expect(story.nodes['Morning']!.ending, Ending.death);
    expect(story.nodes['Lamp-room']!.ending, Ending.victory);
    expect(r.positions['Keeper'], (500.0, 300.0));

    expect(r.report, [
      '"Stairs": Twine code (macros or variables) has no equivalent; it is kept in the text to rewrite by hand',
      '"Lamp room": no links, so it is an ending; taken as a victory (tag it "death" in Twine, or change it here)',
      '"Keeper": the link to "Nowhere" leads to no passage; left out',
      'warning: nodes.Keeper: is unreachable from the start',
    ]);
  });

  test('a published Twine 2 file is read too', () {
    const html = '''
<tw-storydata name="Tiny &amp; Dark" startnode="2" format="SugarCube">
<tw-passagedata pid="1" name="End" tags="" position="400,100">The &quot;end&quot;.</tw-passagedata>
<tw-passagedata pid="2" name="Begin" tags="" position="100,100">It is dark.
[[Go on->End]]</tw-passagedata>
</tw-storydata>''';
    final r = importTwine(html);
    final story = Story.fromJson(r.story);
    expect(story.id, 'tiny-dark');
    expect(story.title, 'Tiny & Dark');
    expect(story.start, 'Begin');
    expect(story.nodes['End']!.text, 'The "end".');
    expect(story.nodes['Begin']!.choices.single.to, 'End');
    expect(r.positions, {'End': (400.0, 100.0), 'Begin': (100.0, 100.0)});
  });

  test('names that are not ids become ids, uniquely', () {
    final r = importTwine(':: A room!\n[[A room?]]\n\n:: A room?\nAgain.\n');
    expect((r.story['nodes']! as Map).keys, ['A-room', 'A-room-2']);
  });

  test('nothing to import is an error', () {
    expect(() => importTwine('just words'), throwsFormatException);
  });

  test('the CLI writes the story and builder.json, and prints the report', () {
    final dir = Directory.systemTemp.createTempSync('twine');
    addTearDown(() => dir.deleteSync(recursive: true));
    final out = StringBuffer();
    expect(runImportTwine(['test/fixtures/lighthouse.twee', dir.path], out), 0);
    expect(File('${dir.path}/story.en.json').existsSync(), isTrue);
    expect(
      File('${dir.path}/builder.json').readAsStringSync(),
      contains('"Keeper"'),
    );
    expect(out.toString(), contains('(5 pages)'));
    expect(out.toString(), contains('- "Keeper": the link to "Nowhere"'));
    expect(runImportTwine(['only-one'], StringBuffer()), 2);
    expect(runImportTwine(['missing.twee', dir.path], StringBuffer()), 1);
  });
}
