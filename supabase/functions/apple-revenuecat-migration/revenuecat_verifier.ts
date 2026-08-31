export const MAX_REVENUECAT_PAGES = 10;
export const MAX_REVENUECAT_SUBSCRIPTIONS = 100;

export type RevenueCatReconciliationState =
  | "ACTIVE_ENTITLEMENT"
  | "INACTIVE_ENTITLEMENT"
  | "NO_PURCHASE_EVIDENCE"
  | "UNAVAILABLE"
  | "INVALID_RESPONSE";

export type RevenueCatReconciliationVerification = {
  state: RevenueCatReconciliationState;
  customerId: string;
  verifiedAt?: string;
};

type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;
type VerificationConfig = {
  secretApiKey: string;
  projectId: string;
  customerId: string;
  entitlementResourceId: string;
  fetcher?: FetchLike;
  now?: () => Date;
};

const ORIGIN = "https://api.revenuecat.com";

function customerPath(project: string, customer: string, resource: string) {
  return `/v2/projects/${encodeURIComponent(project)}/customers/${
    encodeURIComponent(customer)
  }/${resource}`;
}

function subscriptionEntitlementsPath(project: string, subscription: string) {
  return `/v2/projects/${encodeURIComponent(project)}/subscriptions/${
    encodeURIComponent(subscription)
  }/entitlements`;
}

function firstPage(path: string) {
  const url = new URL(path, ORIGIN);
  url.searchParams.set("limit", "100");
  return url;
}

function safeNext(value: unknown, path: string): URL | null {
  if (typeof value !== "string") return null;
  let url: URL;
  try {
    url = new URL(value, ORIGIN);
  } catch {
    return null;
  }
  if (
    url.protocol !== "https:" || url.hostname !== "api.revenuecat.com" ||
    url.port || url.username || url.password || url.hash ||
    url.pathname !== path
  ) return null;
  for (const key of url.searchParams.keys()) {
    if (key !== "starting_after" && key !== "limit") return null;
  }
  return url.searchParams.get("starting_after") ? url : null;
}

type ListResult =
  | { kind: "ok"; items: Record<string, unknown>[] }
  | { kind: "not_found" | "unavailable" | "invalid" };

async function getList(
  path: string,
  apiKey: string,
  fetcher: FetchLike,
): Promise<ListResult> {
  let pageUrl = firstPage(path);
  const visited = new Set<string>();
  const items: Record<string, unknown>[] = [];
  for (let page = 0; page < MAX_REVENUECAT_PAGES; page++) {
    const canonical = pageUrl.toString();
    if (visited.has(canonical)) return { kind: "invalid" };
    visited.add(canonical);
    let response: Response;
    try {
      response = await fetcher(pageUrl, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          Accept: "application/json",
        },
      });
    } catch {
      return { kind: "unavailable" };
    }
    if (response.status === 404) return { kind: "not_found" };
    if (response.status !== 200) return { kind: "unavailable" };
    let payload: unknown;
    try {
      payload = await response.json();
    } catch {
      return { kind: "invalid" };
    }
    if (
      payload == null || typeof payload !== "object" ||
      (payload as Record<string, unknown>).object !== "list" ||
      !Array.isArray((payload as Record<string, unknown>).items)
    ) return { kind: "invalid" };
    const record = payload as Record<string, unknown>;
    for (const item of record.items as unknown[]) {
      if (item == null || typeof item !== "object" || Array.isArray(item)) {
        return { kind: "invalid" };
      }
      items.push(item as Record<string, unknown>);
      if (items.length > MAX_REVENUECAT_SUBSCRIPTIONS) {
        return { kind: "invalid" };
      }
    }
    if (record.next_page == null) return { kind: "ok", items };
    const next = safeNext(record.next_page, path);
    if (next == null) return { kind: "invalid" };
    pageUrl = next;
  }
  return { kind: "invalid" };
}

function failure(
  result: Exclude<ListResult, { kind: "ok" }>,
  customerId: string,
): RevenueCatReconciliationVerification {
  return {
    state: result.kind === "not_found"
      ? "NO_PURCHASE_EVIDENCE"
      : result.kind === "unavailable"
      ? "UNAVAILABLE"
      : "INVALID_RESPONSE",
    customerId,
  };
}

export async function verifyRevenueCatReconciliation(
  config: VerificationConfig,
): Promise<RevenueCatReconciliationVerification> {
  if (
    !config.secretApiKey || !config.projectId ||
    !/^entl[A-Za-z0-9]+$/.test(config.entitlementResourceId) ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(config.customerId)
  ) {
    return { state: "INVALID_RESPONSE", customerId: config.customerId };
  }
  const fetcher = config.fetcher ?? fetch;
  const subscriptions = await getList(
    customerPath(config.projectId, config.customerId, "subscriptions"),
    config.secretApiKey,
    fetcher,
  );
  if (subscriptions.kind !== "ok") {
    return failure(subscriptions, config.customerId);
  }

  const appleSubscriptions: string[] = [];
  for (const item of subscriptions.items) {
    if (
      item.object !== "subscription" || typeof item.id !== "string" ||
      !item.id ||
      item.customer_id !== config.customerId || typeof item.store !== "string"
    ) {
      return { state: "INVALID_RESPONSE", customerId: config.customerId };
    }
    if (item.store === "app_store" || item.store === "mac_app_store") {
      appleSubscriptions.push(item.id);
    }
  }

  let historicalClubEvidence = false;
  for (const subscriptionId of appleSubscriptions) {
    const entitlements = await getList(
      subscriptionEntitlementsPath(config.projectId, subscriptionId),
      config.secretApiKey,
      fetcher,
    );
    if (entitlements.kind !== "ok") {
      return entitlements.kind === "not_found"
        ? { state: "INVALID_RESPONSE", customerId: config.customerId }
        : failure(entitlements, config.customerId);
    }
    for (const item of entitlements.items) {
      if (
        item.object !== "entitlement" || typeof item.id !== "string" || !item.id
      ) {
        return { state: "INVALID_RESPONSE", customerId: config.customerId };
      }
      if (item.id === config.entitlementResourceId) {
        historicalClubEvidence = true;
      }
    }
  }
  if (!historicalClubEvidence) {
    return { state: "NO_PURCHASE_EVIDENCE", customerId: config.customerId };
  }

  const active = await getList(
    customerPath(config.projectId, config.customerId, "active_entitlements"),
    config.secretApiKey,
    fetcher,
  );
  if (active.kind !== "ok") return failure(active, config.customerId);
  let entitlementActive = false;
  for (const item of active.items) {
    if (
      item.object !== "customer.active_entitlement" ||
      typeof item.entitlement_id !== "string" ||
      !(item.expires_at === null ||
        (typeof item.expires_at === "number" &&
          Number.isFinite(item.expires_at)))
    ) {
      return { state: "INVALID_RESPONSE", customerId: config.customerId };
    }
    if (item.entitlement_id === config.entitlementResourceId) {
      entitlementActive = true;
    }
  }
  return {
    state: entitlementActive ? "ACTIVE_ENTITLEMENT" : "INACTIVE_ENTITLEMENT",
    customerId: config.customerId,
    verifiedAt: (config.now ?? (() => new Date()))().toISOString(),
  };
}
