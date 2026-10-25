import {Type} from "@fastify/type-provider-typebox";

export const RuntimeRoleSchema = Type.Union([Type.Literal("admin"), Type.Literal("member")]);

export const RuntimeUserDto = Type.Object({
  uid: Type.String(), loginName: Type.String(), displayName: Type.String(), role: RuntimeRoleSchema,
  hasPassword: Type.Boolean(), createdAt: Type.String(),
});

export const InvitationDto = Type.Object({code: Type.String(), expiresAt: Type.String()});

export const SessionTokenDto = Type.Object({token: Type.String()});

export const RuntimeUserFailure = Type.Object({error: Type.String(), code: Type.Optional(Type.String())});

/** Grobe Größengrenzen; Inhalt und Länge prüft die Domäne mit lesbaren Meldungen. */
export const LoginNameField = Type.String({maxLength: 200});
export const DisplayNameField = Type.String({maxLength: 400});
export const PasswordField = Type.String({maxLength: 1000});
export const LicenseTokenField = Type.Optional(Type.String({maxLength: 400}));
/** Selbstauskunft des Clients beim Anmelden; gekürzt wird in `SessionDevice`. */
export const DeviceField = Type.Optional(Type.Object({
  app: Type.Optional(Type.String({maxLength: 200})),
  os: Type.Optional(Type.String({maxLength: 40})),
  browser: Type.Optional(Type.Union([Type.String({maxLength: 200}), Type.Null()])),
}, {additionalProperties: false}));
