extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Supprime les accents et met tout en minuscules
String _normalize(String text) {
  // Remplace les lettres accentuées par leurs équivalents non accentués
  const accents = 'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿ';
  const sansAccents = 'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOOooooooUUUUuuuuYyy';
  String result = text;

  for (int i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], sansAccents[i]);
  }

  return result.toLowerCase().trim();
}
