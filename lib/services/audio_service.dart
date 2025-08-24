import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// Plays a short sound effect from your assets.
  Future<void> playSound(String soundFile) async {
    try {
      final player = AudioPlayer();
      await _player.play(AssetSource(soundFile));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }
}