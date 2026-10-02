import assert from "node:assert/strict";
import test from "node:test";
import {mailConnectorSummaryFrom} from "./mail-connector-summary.js";
import {type MailConnector} from "./mail-connector.js";

test("die Zusammenfassung enthält nur Anzeigedaten, keine Zugangsdaten oder Subscription", () => {
  const connector: MailConnector = {
    id: "c1", teamId: "team-1", createdByUid: "u1", provider: "microsoftGraph", deliveryTarget: "localRuntime",
    runtimeLicenseId: "lizenz-1", emailAddress: "team@example.com", displayName: "Team", status: "reauthorizationRequired",
    subscriptionId: "geheim-sub", subscriptionExpiresAt: new Date(), createdAt: new Date(), updatedAt: new Date(),
  };

  const summary = mailConnectorSummaryFrom(connector);

  assert.deepEqual(summary, {
    id: "c1", teamId: "team-1", emailAddress: "team@example.com", displayName: "Team", status: "reauthorizationRequired",
  });
});
