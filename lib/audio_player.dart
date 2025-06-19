import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

void jouerSon(String resultat) {
  if (resultat == 'correct') {
    player.play(AssetSource('sounds/correct.mp3'));
  } else {
    player.play(AssetSource('sounds/wrong.mp3'));
  }
}
