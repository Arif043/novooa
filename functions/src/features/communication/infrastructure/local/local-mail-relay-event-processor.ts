import {dispatchChannelMessageEvent} from
  "../../domain/usecases/dispatch-channel-message-event.js";
import {type RuntimeMailRelayDelivery} from
  "../../domain/entities/runtime-mail-relay-event.js";
import {type LocalApplicationLogger} from
  "../../../../shared/logging/local-application-logger.js";
import {type TaskTriggerStore} from
  "../../../scheduling/domain/repositories/task-trigger-store.js";
import {type TaskStore} from
  "../../../task_execution/domain/repositories/task-store.js";
import {type TaskRunStore} from
  "../../../task_execution/domain/repositories/task-run-store.js";
import {type TaskRunDispatcher} from
  "../../../task_execution/domain/repositories/task-run-dispatcher.js";
import {SQLiteInboundChannelMessageStore} from "./sqlite-inbound-channel-message-store.js";

export class LocalMailRelayEventProcessor {
  constructor(
    private readonly messages: SQLiteInboundChannelMessageStore,
    private readonly ports: {
      triggerStore: TaskTriggerStore;
      taskStore: TaskStore;
      taskRunStore: TaskRunStore;
      taskRunDispatcher: TaskRunDispatcher;
    },
    private readonly teamId: string,
    private readonly logger: LocalApplicationLogger,
  ) {}

  async process(delivery: RuntimeMailRelayDelivery): Promise<void> {
    const event = {...delivery.event, connectorId: delivery.connectorId};
    const created = await this.messages.store({
      teamId: this.teamId, eventId: delivery.eventId,
      connectorId: delivery.connectorId, event,
    });
    if (!created) return;
    await dispatchChannelMessageEvent({teamId: this.teamId, channelId: delivery.connectorId, event}, {
      ...this.ports,
      onTriggerFailure: (trigger, error) => this.logger.exception(
        "local_mail_relay.trigger_failed", error, {triggerId: trigger.id, eventId: delivery.eventId},
      ),
    });
  }
}
