import {type MailConnectorAuthorization} from
  "../entities/mail-connector-authorization.js";
import {type MailConnectorRepository} from
  "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";

export async function beginMailConnectorAuthorization(input: {
  authorization: MailConnectorAuthorization;
  codeChallenge: string;
  repository: MailConnectorRepository;
  provider: MailProvider;
}): Promise<{authorizationUrl: string}> {
  await input.repository.createAuthorization(input.authorization);
  const authorization = input.provider.authorizationUrl({
    state: input.authorization.id,
    codeChallenge: input.codeChallenge,
  });
  return {authorizationUrl: authorization.url};
}
