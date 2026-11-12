import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../play/views.dart';

/// Plays a page's music (looping, changed only when it changes) and the
/// sounds of the last action. A missing file or a blocked autoplay is
/// ignored: audio is a nicety, never an error.
class AudioOutput {
  AudioOutput([this.base = '']);

  /// Put in front of every file path (see `PlayerView.mediaBase`).
  final String base;
  HTMLAudioElement? _music;
  String? _playing;

  /// The music file now playing, if any.
  String? get playing => _playing;

  /// Silenced by the player; the music keeps its place and sounds are skipped.
  bool get muted => _muted;
  bool _muted = false;
  set muted(bool value) {
    _muted = value;
    _music?.muted = value;
  }

  void play(AudioCue cue) {
    if (cue.music != _playing) {
      _music?.pause();
      _music = null;
      _playing = cue.music;
      if (cue.music case final file?) {
        _music = HTMLAudioElement()
          ..src = '$base$file'
          ..loop = true
          ..muted = _muted;
        _start(_music!);
      }
    }
    if (_muted) return;
    for (final file in cue.sounds) {
      _start(HTMLAudioElement()..src = '$base$file');
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
