import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../play/views.dart';

/// Plays a page's music (looping, changed only when it changes) and the
/// sounds of the last action. A missing file or a blocked autoplay is
/// ignored: audio is a nicety, never an error.
class AudioOutput {
  HTMLAudioElement? _music;
  String? _playing;

  void play(AudioCue cue) {
    if (cue.music != _playing) {
      _music?.pause();
      _music = null;
      _playing = cue.music;
      if (cue.music case final file?) {
        _music = HTMLAudioElement()
          ..src = file
          ..loop = true;
        _start(_music!);
      }
    }
    for (final file in cue.sounds) {
      _start(HTMLAudioElement()..src = file);
    }
  }

  void stop() {
    _music?.pause();
    _music = null;
    _playing = null;
  }

  static void _start(HTMLAudioElement audio) =>
      unawaited(audio.play().toDart.then((_) {}, onError: (Object _) {}));
}
