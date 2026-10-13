/// Seitenränder ruhiger Listenseiten: schmaler Rand auf dem Handy, ab 1080 px
/// eine mittige Spalte von 1000 px.
class PageInsets {
  const PageInsets._(this.gutter, this.inset);

  factory PageInsets.forWidth(double maxWidth) {
    final gutter = maxWidth < 600 ? 20.0 : 40.0;
    final inset = maxWidth > 1080 ? (maxWidth - 1000) / 2 : gutter;
    return PageInsets._(gutter, inset);
  }

  /// Abstand für Zustände, die die ganze Seite füllen.
  final double gutter;

  /// Seitlicher Abstand von Kopfzeile und Liste.
  final double inset;
}
