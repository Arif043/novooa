import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';

void main() {
  test('nativ gilt ohne dart-define die lokale Runtime-Adresse', () {
    expect(
      RuntimeProfile.fromEnvironment().workspaceApiUri,
      Uri.parse('http://127.0.0.1:8090'),
    );
  });

  test('withWorkspaceApiUri ersetzt die Adresse', () {
    final moved = RuntimeProfile.fromEnvironment().withWorkspaceApiUri(
      Uri.parse('http://host:9000'),
    );

    expect(moved.workspaceApiUri, Uri.parse('http://host:9000'));
  });
}
