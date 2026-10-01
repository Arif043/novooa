import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/workspace_transfer/domain/entities/transfer_category.dart';
import 'package:syscat2/features/workspace_transfer/infrastructure/models/transfer_response_model.dart';

void main() {
  test('maps a staged import and ignores unknown categories', () {
    final staged = TransferResponseModel.stagedImportFrom({
      'importId': 'import-1',
      'manifest': {
        'exportedAt': '2026-10-01T08:30:00.000Z',
        'counts': {'tasks': 2, 'files': 3, 'triggers': 9},
      },
    });

    expect(staged.id.value, 'import-1');
    expect(staged.contents.categories, [
      TransferCategory.files,
      TransferCategory.tasks,
    ]);
    expect(staged.contents.countOf(TransferCategory.files), 3);
  });

  test('rejects an incomplete response', () {
    expect(
      () => TransferResponseModel.stagedImportFrom({'importId': 'import-1'}),
      throwsFormatException,
    );
  });
}
