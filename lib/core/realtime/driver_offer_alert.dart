import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';

/// رنّة عروض الدليفرية، عشان المغسلة تاخد بالها حتى لو مش جنب الموبايل
/// بتفضل ترن لحد ما حد يلمس الشيت أو يقفله أو [_maxDuration] تخلص،
/// ومابتقفش لو الشاشة قفلت لوحدها والأبلكيشن راح الخلفية
abstract final class DriverOfferAlert {
  /// جوه assets/ زي ما AssetSource بيتوقع
  static const String _sound = 'sounds/driver_offer.wav';

  static const Duration _maxDuration = Duration(seconds: 60);
  static const Duration _vibrationInterval = Duration(seconds: 2);

  static AudioPlayer? _player;
  static Timer? _timeout;
  static Timer? _vibration;

  /// كل start أو stop بيزوّده، عشان play اللي لسه مخلصش مايرنّش بعد الإيقاف
  static int _generation = 0;

  static bool get isRinging => _timeout != null;

  /// بيوطّي أي صوت شغال بدل ما يوقفه، وفي iOS بيرن حتى لو زرار الصامت متفعّل
  static final AudioContext _audioContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.notificationRingtone,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.duckOthers},
    ),
  );

  static Future<AudioPlayer> _audio() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    await player.setAudioContext(_audioContext);
    return _player = player;
  }

  /// رنّة متكررة واهتزاز كل شوية
  static Future<void> startRinging() async {
    final generation = ++_generation;
    _timeout?.cancel();
    _timeout = Timer(_maxDuration, stop);
    _vibration?.cancel();
    HapticFeedback.vibrate();
    _vibration = Timer.periodic(
      _vibrationInterval,
      (_) => HapticFeedback.vibrate(),
    );
    await _play(generation, ReleaseMode.loop);
  }

  /// مرة واحدة لعرض جديد والمستخدم قدام العروض أصلاً
  static Future<void> chimeOnce() async {
    HapticFeedback.heavyImpact();
    if (isRinging) return;
    await _play(++_generation, ReleaseMode.stop);
  }

  static Future<void> stop() async {
    _generation++;
    _timeout?.cancel();
    _timeout = null;
    _vibration?.cancel();
    _vibration = null;
    try {
      await _player?.stop();
    } catch (e) {
      loggerWarn('Driver offer alert stop failed: $e');
    }
  }

  static Future<void> _play(int generation, ReleaseMode mode) async {
    try {
      final player = await _audio();
      if (generation != _generation) return;
      await player.stop();
      await player.setReleaseMode(mode);
      if (generation != _generation) return;
      await player.play(AssetSource(_sound));
      // اتوقف واحنا بنشغّل
      if (generation != _generation) await player.stop();
    } catch (e) {
      loggerWarn('Driver offer alert play failed: $e');
    }
  }
}
