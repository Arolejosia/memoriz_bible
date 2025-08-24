import 'audio_service.dart';
import 'feedback_overlay.dart';

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  /// Joue un son et affiche un message animé en même temps
  Future<void> showSuccess(String message) async {
    // ✅ Affichage visuel


    // ✅ Son associé
    await AudioService.instance.playSound("sounds/correct.mp3");
  }

}
