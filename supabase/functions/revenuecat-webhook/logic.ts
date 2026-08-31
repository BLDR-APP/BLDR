export const CLUB_ENTITLEMENT_ID = "bldr_club";
export const REVENUECAT_SIGNATURE_TOLERANCE_SECONDS = 5 * 60;

export type WebhookAuthenticationResult =
  | { authenticated: true }
  | {
    authenticated: false;
    reason:
      | "invalid_authorization"
      | "invalid_signature"
      | "expired_signature";
  };

export type RevenueCatEvent = Record<string, unknown> & {
  id?: unknown;
  type?: unknown;
  event_timestamp_ms?: unknown;
  app_user_id?: unknown;
  original_app_user_id?: unknown;
  aliases?: unknown;
  product_id?: unknown;
  new_product_id?: unknown;
  store?: unknown;
  period_type?: unknown;
  purchased_at_ms?: unknown;
  expiration_at_ms?: unknown;
  grace_period_expiration_at_ms?: unknown;
  cancel_reason?: unknown;
  expiration_reason?: unknown;
  is_trial_conversion?: unknown;
  transferred_from?: unknown;
  transferred_to?: unknown;
  entitlement_id?: unknown;
  entitlement_ids?: unknown;
};

export type MirrorMapping = {
  applyMirror: boolean;
  entitlementId: string | null;
  productId: string | null;
  store: string | null;
  status: "active" | "canceled" | "past_due" | "unpaid" | "trialing" | null;
  billingPeriod: "weekly" | "monthly" | "annual" | null;
  currentPeriodStart: string | null;
  currentPeriodEnd: string | null;
  willRenew: boolean | null;
  reason: string;
};

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

function strings(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

export function orderedIdentityCandidates(event: RevenueCatEvent): string[] {
  const raw = [
    event.app_user_id,
    event.original_app_user_id,
    ...strings(event.aliases),
    ...strings(event.transferred_to),
    ...strings(event.transferred_from),
  ];
  return [...new Set(raw.filter(isUuid))];
}

export function rawAppUserId(event: RevenueCatEvent): string | null {
  const candidates = [
    event.app_user_id,
    event.original_app_user_id,
    ...strings(event.transferred_to),
    ...strings(event.transferred_from),
  ];
  return candidates.find((value): value is string =>
    typeof value === "string" && value.length > 0
  ) ?? null;
}

function numberValue(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

export function millisToIso(value: unknown): string | null {
  const milliseconds = numberValue(value);
  if (milliseconds === null || milliseconds < 0) return null;
  const date = new Date(milliseconds);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function hasClubEntitlement(event: RevenueCatEvent): boolean {
  return event.entitlement_id === CLUB_ENTITLEMENT_ID ||
    strings(event.entitlement_ids).includes(CLUB_ENTITLEMENT_ID);
}

export function billingPeriodFor(
  productId: string | null,
  purchasedAtMs: number | null,
  expirationAtMs: number | null,
): MirrorMapping["billingPeriod"] {
  const normalized = productId?.toUpperCase() ?? "";
  if (normalized === "CLUBWEEKLY" || normalized.endsWith(".CLUBWEEKLY")) {
    return "weekly";
  }
  if (normalized === "MENSAL" || normalized.endsWith(".MENSAL")) {
    return "monthly";
  }
  if (normalized === "ANUAL" || normalized.endsWith(".ANUAL")) return "annual";

  if (
    purchasedAtMs === null || expirationAtMs === null ||
    expirationAtMs <= purchasedAtMs
  ) {
    return null;
  }
  const days = (expirationAtMs - purchasedAtMs) / 86_400_000;
  if (days >= 5 && days <= 9) return "weekly";
  if (days >= 25 && days <= 35) return "monthly";
  if (days >= 330 && days <= 400) return "annual";
  return null;
}

export function mapRevenueCatEvent(
  event: RevenueCatEvent,
  nowMs = Date.now(),
): MirrorMapping {
  const type = typeof event.type === "string" ? event.type : "";
  const productId = typeof event.product_id === "string"
    ? event.product_id
    : null;
  const effectiveProductId = type === "PRODUCT_CHANGE" &&
      typeof event.new_product_id === "string"
    ? event.new_product_id
    : productId;
  const purchasedAtMs = numberValue(event.purchased_at_ms);
  const expirationAtMs = numberValue(event.expiration_at_ms);
  const graceAtMs = numberValue(event.grace_period_expiration_at_ms);
  const effectiveEndMs = graceAtMs !== null &&
      (expirationAtMs === null || graceAtMs > expirationAtMs)
    ? graceAtMs
    : expirationAtMs;
  const trial = event.period_type === "TRIAL";
  const accessStillCurrent = effectiveEndMs !== null && effectiveEndMs > nowMs;
  const relevantEntitlement = hasClubEntitlement(event);
  const completeCommercialState = effectiveEndMs !== null &&
    effectiveProductId !== null &&
    billingPeriodFor(effectiveProductId, purchasedAtMs, expirationAtMs) !==
      null;
  const base = {
    entitlementId: relevantEntitlement ? CLUB_ENTITLEMENT_ID : null,
    productId: effectiveProductId,
    store: typeof event.store === "string" ? event.store : null,
    billingPeriod: billingPeriodFor(
      effectiveProductId,
      purchasedAtMs,
      expirationAtMs,
    ),
    currentPeriodStart: millisToIso(purchasedAtMs),
    currentPeriodEnd: millisToIso(effectiveEndMs),
  };

  if (!relevantEntitlement) {
    return {
      ...base,
      applyMirror: false,
      status: null,
      willRenew: null,
      reason: "unrelated_entitlement",
    };
  }

  switch (type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
      return {
        ...base,
        applyMirror: completeCommercialState,
        status: completeCommercialState
          ? (trial ? "trialing" : "active")
          : null,
        willRenew: true,
        reason: completeCommercialState
          ? type.toLowerCase()
          : "incomplete_commercial_state",
      };
    case "CANCELLATION":
      return {
        ...base,
        applyMirror: true,
        status: effectiveEndMs === null
          ? null
          : accessStillCurrent
          ? (trial ? "trialing" : "active")
          : "canceled",
        willRenew: false,
        reason: "cancellation_access_until_expiry",
      };
    case "UNCANCELLATION":
      return {
        ...base,
        applyMirror: true,
        status: accessStillCurrent ? (trial ? "trialing" : "active") : null,
        willRenew: true,
        reason: "uncancellation",
      };
    case "EXPIRATION":
      return {
        ...base,
        applyMirror: effectiveEndMs !== null,
        status: effectiveEndMs !== null ? "canceled" : null,
        willRenew: false,
        reason: "expiration",
      };
    case "BILLING_ISSUE":
      return {
        ...base,
        applyMirror: true,
        status: effectiveEndMs === null
          ? null
          : accessStillCurrent
          ? (trial ? "trialing" : "active")
          : "past_due",
        willRenew: true,
        reason: accessStillCurrent
          ? "billing_issue_access_current"
          : "billing_issue_past_due",
      };
    case "NON_RENEWING_PURCHASE":
      return {
        ...base,
        applyMirror: true,
        status: effectiveEndMs === null
          ? null
          : accessStillCurrent
          ? "active"
          : "canceled",
        willRenew: false,
        reason: "non_renewing_purchase",
      };
    case "SUBSCRIPTION_PAUSED":
      return {
        ...base,
        applyMirror: true,
        status: effectiveEndMs === null
          ? null
          : accessStillCurrent
          ? "active"
          : "canceled",
        willRenew: false,
        reason: "subscription_paused",
      };
    case "SUBSCRIPTION_EXTENDED":
      return {
        ...base,
        applyMirror: effectiveEndMs !== null,
        status: accessStillCurrent ? "active" : null,
        willRenew: null,
        reason: "subscription_extended",
      };
    case "PRODUCT_CHANGE":
      return {
        ...base,
        applyMirror: false,
        status: null,
        willRenew: null,
        reason: "product_change_waits_for_commercial_event",
      };
    case "TRANSFER":
      return {
        ...base,
        applyMirror: false,
        status: null,
        willRenew: null,
        reason: "transfer_ledger_only",
      };
    default:
      return {
        ...base,
        applyMirror: false,
        status: null,
        willRenew: null,
        reason: "unsupported_event_ledger_only",
      };
  }
}

export async function constantTimeEquals(
  actual: string,
  expected: string,
): Promise<boolean> {
  const encoder = new TextEncoder();
  const actualDigest = new Uint8Array(
    await crypto.subtle.digest("SHA-256", encoder.encode(actual)),
  );
  const expectedDigest = new Uint8Array(
    await crypto.subtle.digest("SHA-256", encoder.encode(expected)),
  );
  let difference = 0;
  for (let index = 0; index < actualDigest.length; index++) {
    difference |= actualDigest[index] ^ expectedDigest[index];
  }
  return difference === 0;
}

function concatBytes(first: Uint8Array, second: Uint8Array): Uint8Array {
  const combined = new Uint8Array(first.length + second.length);
  combined.set(first);
  combined.set(second, first.length);
  return combined;
}

async function hmacSha256Hex(
  secret: string,
  message: Uint8Array,
): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const messageBuffer = new Uint8Array(message.byteLength);
  messageBuffer.set(message);
  const digest = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, messageBuffer),
  );
  return [...digest]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

type ParsedRevenueCatSignature = {
  timestampText: string;
  timestampSeconds: number;
  signatures: string[];
};

function parseRevenueCatSignature(
  header: string,
): ParsedRevenueCatSignature | null {
  let timestampText: string | null = null;
  const signatures: string[] = [];

  for (const component of header.split(",")) {
    const separator = component.indexOf("=");
    if (separator <= 0) continue;
    const key = component.slice(0, separator).trim();
    const value = component.slice(separator + 1).trim();
    if (key === "t") {
      if (timestampText !== null && timestampText !== value) return null;
      timestampText = value;
    } else if (key === "v1" && /^[0-9a-f]{64}$/i.test(value)) {
      signatures.push(value.toLowerCase());
    }
  }

  if (timestampText === null || signatures.length === 0) return null;
  if (!/^[0-9]+$/.test(timestampText)) return null;
  const timestampSeconds = Number(timestampText);
  if (!Number.isSafeInteger(timestampSeconds) || timestampSeconds <= 0) {
    return null;
  }
  return { timestampText, timestampSeconds, signatures };
}

export async function createRevenueCatSignature(
  rawBody: Uint8Array,
  timestampSeconds: number,
  signingSecret: string,
): Promise<string> {
  const timestampText = Math.trunc(timestampSeconds).toString();
  const prefix = new TextEncoder().encode(`${timestampText}.`);
  const signature = await hmacSha256Hex(
    signingSecret,
    concatBytes(prefix, rawBody),
  );
  return `t=${timestampText},v1=${signature}`;
}

export async function authenticateRevenueCatWebhook(
  receivedAuthorization: string,
  expectedAuthorization: string,
  signatureHeader: string,
  signingSecret: string,
  rawBody: Uint8Array,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<WebhookAuthenticationResult> {
  if (
    expectedAuthorization.length === 0 ||
    !await constantTimeEquals(receivedAuthorization, expectedAuthorization)
  ) {
    return { authenticated: false, reason: "invalid_authorization" };
  }

  const parsed = parseRevenueCatSignature(signatureHeader);
  if (parsed === null || signingSecret.length === 0) {
    return { authenticated: false, reason: "invalid_signature" };
  }
  if (
    Math.abs(nowSeconds - parsed.timestampSeconds) >
      REVENUECAT_SIGNATURE_TOLERANCE_SECONDS
  ) {
    return { authenticated: false, reason: "expired_signature" };
  }

  const prefix = new TextEncoder().encode(`${parsed.timestampText}.`);
  const expectedSignature = await hmacSha256Hex(
    signingSecret,
    concatBytes(prefix, rawBody),
  );
  for (const candidate of parsed.signatures) {
    if (await constantTimeEquals(candidate, expectedSignature)) {
      return { authenticated: true };
    }
  }
  return { authenticated: false, reason: "invalid_signature" };
}
