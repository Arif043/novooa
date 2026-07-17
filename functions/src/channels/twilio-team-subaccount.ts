import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import twilio from "twilio";
import {initializeAdminApp} from "../team-context.js";

export async function ensureTeamTwilioSubaccount(input: {
  teamId: string;
  parentAccountSid: string;
  authToken: string;
}): Promise<string> {
  initializeAdminApp();
  const team = await teamReference(input.teamId).get();
  const existingSid = subaccountSidFrom(team.data());
  if (existingSid) return existingSid;
  const createdSid = await createSubaccount(input);
  await teamReference(input.teamId).set(subaccountDocument(createdSid), {
    merge: true,
  });
  return createdSid;
}

async function createSubaccount(input: {
  teamId: string;
  parentAccountSid: string;
  authToken: string;
}): Promise<string> {
  const client = twilio(input.parentAccountSid, input.authToken);
  const account = await client.api.accounts.create({
    friendlyName: `novooa Team ${input.teamId}`,
  });
  const sid = subaccountSidFrom({twilioSubaccountSid: account.sid});
  if (!sid) throw new HttpsError("internal", "Twilio subaccount missing.");
  return sid;
}

function teamReference(teamId: string) {
  return getFirestore().collection("teams").doc(teamId);
}

function subaccountDocument(twilioSubaccountSid: string) {
  return {
    twilioSubaccountSid,
    twilioStatus: "active",
    twilioProvisionedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function subaccountSidFrom(
  data: Record<string, unknown> | undefined,
): string | null {
  const sid = data?.twilioSubaccountSid;
  return typeof sid === "string" && sid.startsWith("AC") ? sid : null;
}
