import 'package:gamebook_site/src/play/views.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:test/test.dart';

const m = Messages({
  'player.needs': 'Needs: {list}',
  'player.not': 'no {what}',
  'player.locked': 'Locked',
  'player.visits': '{name} visits {op} {target}',
  'player.items': '{count} × {item}',
});

void main() {
  test('a locked choice lists what it needs', () {
    const choice = ChoiceItem(
      index: 0,
      text: 'Pay',
      locked: true,
      needs: [
        Requirement(RequirementKind.item, 'Rusty key'),
        Requirement(RequirementKind.stat, 'Gold', op: CompareOp.gte, target: 5),
        Requirement(RequirementKind.flag, 'cursed', negated: true),
      ],
    );
    expect(lockedReason(choice, m), 'Needs: Rusty key, Gold ≥ 5, no cursed');
  });

  test('an item needed several times names how many', () {
    const r = Requirement(RequirementKind.item, 'Meal', target: 2);
    expect(requirementText(r, m), '2 × Meal');
  });

  test("the author's locked text wins; nothing to name says Locked", () {
    const worded = ChoiceItem(index: 0, text: 'x', lockedText: 'Too poor');
    const bare = ChoiceItem(index: 0, text: 'x', locked: true);
    expect(lockedReason(worded, m), 'Too poor');
    expect(lockedReason(bare, m), 'Locked');
  });

  test('visit counts and missing keys', () {
    const r = Requirement(
      RequirementKind.visits,
      'inn',
      op: CompareOp.lte,
      target: 1,
    );
    expect(requirementText(r, m), 'inn visits ≤ 1');
    expect(m('player.nope'), 'player.nope');
  });

  test('a log line is worded from player.log.<key>', () {
    const words = Messages({'player.log.used': 'Used {item}'});
    expect(
      logText(const LogLine('used', {'item': 'Potion'}), words),
      'Used Potion',
    );
  });

  test('choice index is two digits', () {
    expect(choiceIndex(0), '[01] //');
    expect(choiceIndex(11), '[12] //');
  });
}
