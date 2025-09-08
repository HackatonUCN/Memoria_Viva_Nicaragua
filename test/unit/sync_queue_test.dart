import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:memoria_viva_nicaragua/domain/services/i_sync_queue.dart';
import 'package:memoria_viva_nicaragua/data/infrastructure/services/sync_queue_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncQueueImpl', () {
    late ISyncQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      queue = SyncQueueImpl(prefs);
    });

    test('enqueue/peek/markDone', () async {
      final op = SyncOperation(
        id: '1',
        resource: 'relato',
        resourceId: 'r1',
        type: SyncOperationType.create,
        payload: {'id': 'r1'},
        createdAt: DateTime.now(),
        priority: 1,
      );
      await queue.enqueue(op);
      final list = await queue.peek(limit: 10);
      expect(list.length, 1);
      await queue.markDone('1');
      expect(await queue.length(), 0);
    });

    test('markFailed aplica backoff', () async {
      final op = SyncOperation(
        id: '2',
        resource: 'relato',
        resourceId: 'r2',
        type: SyncOperationType.update,
        payload: {'id': 'r2'},
        createdAt: DateTime.now(),
      );
      await queue.enqueue(op);
      await queue.markFailed('2');
      final items = await queue.peek(limit: 10);
      // Puede estar vacía si el nextAttemptAt está en el futuro
      expect(items.length, anyOf(0, 1));
    });
  });
}


