import 'package:flutter/scheduler.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_writer.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

typedef FrameWaiter = Future<void> Function();

Future<void> waitForNextFrame() => SchedulerBinding.instance.endOfFrame;

/// Befüllt Felder eines Bausteins; mit Cursor sichtbar, sonst direkt.
///
/// Die Navigation (Baustein auswählen, hinfahren, tippen) entsteht hier und
/// nicht im Modellvorschlag: der Agent liefert nur Feld und Wert.
class NodeFieldPlayer {
  const NodeFieldPlayer(this._cubit, {this.waitForFrame = waitForNextFrame});

  final TaskBuilderCubit _cubit;

  /// Wartet, bis das Bedienfeld des Bausteins gebaut ist (im Test ersetzbar).
  final FrameWaiter waitForFrame;

  Future<void> fill(
    NodeId nodeId,
    Map<NodeFieldKey, String> fields, {
    AgentCursorPerformer? cursor,
  }) async {
    final writer = NodeFieldWriter(_cubit);
    if (cursor != null) await _reveal(nodeId, cursor);
    for (final entry in fields.entries) {
      await _fillField(writer, nodeId, entry.key, entry.value, cursor);
    }
  }

  Future<void> _reveal(NodeId nodeId, AgentCursorPerformer cursor) async {
    await waitForFrame();
    await cursor.click(TaskBuilderCursorTargets.node(nodeId));
    await waitForFrame();
  }

  Future<void> _fillField(
    NodeFieldWriter writer,
    NodeId nodeId,
    NodeFieldKey key,
    String text,
    AgentCursorPerformer? cursor,
  ) {
    if (cursor == null || !key.isTypedByCursor) {
      return writer.write(nodeId, key, text);
    }
    return cursor.typeInto(
      TaskBuilderCursorTargets.field(nodeId, key),
      text,
      (partial) => writer.write(nodeId, key, partial),
    );
  }
}
