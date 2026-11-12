import 'package:gamebook_site/src/play/views.dart';
import 'package:gamebook_site/src/ui/wording.dart';
import 'package:test/test.dart';

const m = Messages({
  'player.needs': 'Needs: {list}',
  'player.not': 'no {what}',
  'player.locked': 'Locked',
  'player.visits': '{name} visits {op} {target}',
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

  test('choice index is two digits', () {
    expect(choiceIndex(0), '[01] //');
    expect(choiceIndex(11), '[12] //');
  });
}
