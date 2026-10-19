/// Die Posen von Noovi, dem Maskottchen, das alle Agenten verkörpert.
enum NooviPose {
  /// Winkt: Begrüßung, Agent öffnen.
  wave('noovi_wave'),

  /// Hand am Kinn: denkt nach, arbeitet.
  thinking('noovi_thinking'),

  /// Arme ausgebreitet: freut sich, fertig.
  cheer('noovi_cheer'),

  /// Daumen hoch: bestanden, einverstanden.
  thumbsUp('noovi_thumbs_up'),

  /// Zeigt auf etwas: antwortet, präsentiert.
  present('noovi_present'),

  /// Fliegt los: ist unterwegs, bedient die Oberfläche.
  fly('noovi_fly');

  const NooviPose(this._fileName);

  final String _fileName;

  String get assetPath => 'assets/images/noovi/$_fileName.png';
}
