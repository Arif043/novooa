import 'package:uuid/uuid.dart';

class UniqueId {
  const UniqueId(this.value) : assert(value.length > 0);

  UniqueId.random() : value = const Uuid().v4();

  final String value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UniqueId &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
