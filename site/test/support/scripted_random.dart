import 'dart:math';

/// A [Random] that plays back the die faces a test wants, in order.
/// `nextInt(n)` returns `face - 1`, so a die rolls exactly the scripted face.
class ScriptedRandom implements Random {
  ScriptedRandom(Iterable<int> faces) : _faces = List.of(faces);

  final List<int> _faces;
  int _next = 0;

  /// Faces not used yet; tests assert it is 0 to catch unexpected rolls.
  int get remaining => _faces.length - _next;

  @override
  int nextInt(int max) {
    final face = _faces[_next++];
    assert(face >= 1 && face <= max, 'scripted face $face is not on a d$max');
    return face - 1;
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}
