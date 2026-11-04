import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'pets.dart';

/// Short sounds (design/sounds/make_sounds.py; all made by the program).
enum Sfx {
  tap,
  pop,
  star,
  strokeDone('stroke_done'),
  letterDone('letter_done'),
  oops,
  celebrate,
  cookie,
  chew,
  bubbles,
  rinse,
  ball,
  lightsOut('lights_out'),
  crack,
  giggle,
  happy,
  callPuppy('call_puppy'),
  callKitten('call_kitten'),
  callBunny('call_bunny'),
  callDino('call_dino'),
  callDolphin('call_dolphin'),
  callOctopus('call_octopus'),
  callTurtle('call_turtle');

  const Sfx([this._file]);

  final String? _file;

  String get file => _file ?? name;

  static Sfx callOf(Species s) => switch (s) {
        Species.puppy => callPuppy,
        Species.kitten => callKitten,
        Species.bunny => callBunny,
        Species.dino => callDino,
        Species.dolphin => callDolphin,
        Species.octopus => callOctopus,
        Species.turtle => callTurtle,
      };
}

/// The music, which changes with what is going on (docs/design.md
/// "背景音樂").
enum Music {
  homeLand('music_home_land'),
  homeSea('music_home_sea'),
  write('music_write'),
  play('music_play'),
  sleep('music_sleep');

  const Music(this.file);

  final String file;

  static Music homeOf(Species? s) => s?.sea == true ? homeSea : homeLand;
}

abstract interface class Sounds {
  set music(bool on);
  set effects(bool on);

  void play(Sfx sfx);

  /// [owner] (a screen) wants [music]; the one asked for last plays.
  void hold(Object owner, Music? music);

  void release(Object owner);
}

/// The screens that want music, in the order they asked.
class MusicHolders {
  final _holders = <Object, Music?>{};

  void hold(Object owner, Music? music) {
    _holders.remove(owner);
    _holders[owner] = music;
  }

  void release(Object owner) => _holders.remove(owner);

  Music? get current => _holders.isEmpty ? null : _holders.values.last;
}

class SilentSounds implements Sounds {
  const SilentSounds();

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(Sfx sfx) {}

  @override
  void hold(Object owner, Music? music) {}

  @override
  void release(Object owner) {}
}

/// Plays through audioplayers: a pool per sound, one looping player for
/// the music. Quiet while the app is in the background.
class SystemSounds implements Sounds {
  SystemSounds() {
    _lifecycle = AppLifecycleListener(onHide: () => _setAway(true), onShow: () => _setAway(false));
  }

  static const _sfxVolume = 0.8, _musicVolume = 0.32;

  late final AppLifecycleListener _lifecycle;
  final _pools = <Sfx, Future<AudioPool>>{};
  final _holders = MusicHolders();
  Future<void>? _setUp;
  AudioPlayer? _loop;
  Music? _playing;
  var _music = true, _effects = true, _away = false;

  @override
  set music(bool on) {
    _music = on;
    _update();
  }

  @override
  set effects(bool on) => _effects = on;

  void _setAway(bool away) {
    _away = away;
    _update();
  }

  Future<void> _ready() => _setUp ??= AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build(),
      );

  @override
  void play(Sfx sfx) {
    if (!_effects || _away) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(Sfx sfx) async {
    try {
      await _ready();
      final pool = await (_pools[sfx] ??= AudioPool.createFromAsset(path: 'sounds/${sfx.file}.wav', maxPlayers: 3));
      await pool.start(volume: _sfxVolume);
    } catch (_) {
      // No audio on this phone, or it failed once: silence is fine.
      _pools.remove(sfx);
    }
  }

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _update();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _update();
  }

  void _update() {
    final wanted = !_music || _away ? null : _holders.current;
    if (wanted == _playing) return;
    _playing = wanted;
    unawaited(_switchTo(wanted));
  }

  Future<void> _switchTo(Music? music) async {
    try {
      await _ready();
      var loop = _loop;
      if (loop == null) {
        loop = _loop = AudioPlayer();
        await loop.setReleaseMode(ReleaseMode.loop);
      }
      await loop.stop();
      if (music == null || music != _playing) return;
      await loop.setVolume(_musicVolume);
      await loop.play(AssetSource('sounds/${music.file}.wav'));
    } catch (_) {}
  }

  void dispose() {
    _lifecycle.dispose();
    unawaited(_loop?.dispose());
  }
}
