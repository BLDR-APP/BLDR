export const CLUB_ENTITLEMENT_ID = "bldr_club";

export type MigrationRow = {
  user_id: string;
  status: string;
  claim_id: string | null;
  claim_expires_at: string | null;
  attempt_count: number;
  last_attempt_at: string | null;
  last_error_code: string | null;
};

export type ClaimResult = {
  claimed: boolean;
  claim_id?: string;
  claim_expires_at?: string;
  attempt_count?: number;
  reason?: string;
};

export type RevenueCatVerification = {
  customerId: string;
  result:
    | "active_entitlement"
    | "inactive_entitlement"
    | "no_purchase_evidence";
  verifiedAt?: string;
};

export type CoordinatorDependencies = {
  authenticate(accessToken: string): Promise<string>;
  getMigration(userId: string): Promise<MigrationRow | null>;
  claim(userId: string, allowNoEvidenceRetry: boolean): Promise<ClaimResult>;
  verifyRevenueCat(userId: string): Promise<RevenueCatVerification>;
  complete(input: {
    userId: string;
    claimId: string;
    verifiedAt: string;
    entitlementActive: boolean;
    reconciliationResult: "active_entitlement" | "inactive_entitlement";
  }): Promise<boolean>;
  fail(input: {
    userId: string;
    claimId: string;
    errorCode:
      | "RC_SYNC_FAILED"
      | "RC_NO_PURCHASE_EVIDENCE"
      | "RC_IDENTITY_MISMATCH";
  }): Promise<boolean>;
  now(): number;
};

export class RequestFailure extends Error {
  constructor(
    readonly statusCode: number,
    readonly publicCode: string,
  ) {
    super(publicCode);
  }
}

export function bearerToken(header: string | null): string {
  const match = header?.match(/^Bearer\s+(.+)$/i);
  if (!match?.[1]) throw new RequestFailure(401, "unauthorized");
  return match[1];
}

function liveClaim(
  row: MigrationRow | null,
  userId: string,
  claimId: string,
  now: number,
): row is MigrationRow {
  if (
    !row || row.user_id !== userId || row.status !== "in_progress" ||
    row.claim_id !== claimId || !row.claim_expires_at
  ) return false;
  const expiresAt = Date.parse(row.claim_expires_at);
  return Number.isFinite(expiresAt) && expiresAt > now;
}

function claimIdFrom(body: Record<string, unknown>): string {
  const claimId = body.claim_id;
  if (
    typeof claimId !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(claimId)
  ) throw new RequestFailure(400, "invalid_claim_id");
  return claimId;
}

const noEvidenceRetryCooldownMs = 7 * 24 * 60 * 60 * 1000;
const maxAutomaticAttempts = 3;

function mayRetryNoEvidence(row: MigrationRow, now: number): boolean {
  if (
    row.status !== "failed" ||
    row.last_error_code !== "RC_NO_PURCHASE_EVIDENCE" ||
    row.attempt_count >= maxAutomaticAttempts ||
    !row.last_attempt_at
  ) return false;
  const previousAttempt = Date.parse(row.last_attempt_at);
  return Number.isFinite(previousAttempt) &&
    previousAttempt <= now - noEvidenceRetryCooldownMs;
}

export function createHandler(dependencies: CoordinatorDependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") return response(200, { ok: true });
    if (request.method !== "POST") {
      return response(405, { error: "method_not_allowed" });
    }

    try {
      const accessToken = bearerToken(request.headers.get("authorization"));
      const userId = await dependencies.authenticate(accessToken);
      let body: Record<string, unknown>;
      try {
        body = await request.json();
      } catch {
        throw new RequestFailure(400, "invalid_body");
      }
      const operation = body.operation;

      if (operation === "claim") {
        const row = await dependencies.getMigration(userId);
        const claimExpiry = row?.claim_expires_at == null
          ? Number.NaN
          : Date.parse(row.claim_expires_at);
        const isEligible = row?.status === "eligible";
        const isStale = row?.status === "in_progress" &&
          Number.isFinite(claimExpiry) && claimExpiry <= dependencies.now();
        const isNoEvidenceRetry = row != null &&
          mayRetryNoEvidence(row, dependencies.now());
        if (
          !row || row.user_id !== userId ||
          (!isEligible && !isStale && !isNoEvidenceRetry)
        ) {
          return response(200, { claimed: false, reason: "not_claimable" });
        }
        const result = await dependencies.claim(userId, isNoEvidenceRetry);
        return response(200, {
          claimed: result.claimed,
          claim_id: result.claim_id,
          claim_expires_at: result.claim_expires_at,
          attempt_count: result.attempt_count,
          reason: result.reason,
        });
      }

      if (operation === "verify_and_complete") {
        const claimId = claimIdFrom(body);
        const row = await dependencies.getMigration(userId);
        if (!liveClaim(row, userId, claimId, dependencies.now())) {
          throw new RequestFailure(409, "claim_not_live");
        }

        let verification: RevenueCatVerification;
        try {
          verification = await dependencies.verifyRevenueCat(userId);
        } catch {
          // Operational RevenueCat failures do not consume the claim. It expires
          // naturally and can only be retried through an explicitly authorized flow.
          throw new RequestFailure(503, "revenuecat_unavailable");
        }
        if (verification.customerId !== userId) {
          await dependencies.fail({
            userId,
            claimId,
            errorCode: "RC_IDENTITY_MISMATCH",
          });
          throw new RequestFailure(409, "revenuecat_identity_mismatch");
        }
        if (verification.result === "no_purchase_evidence") {
          await dependencies.fail({
            userId,
            claimId,
            errorCode: "RC_NO_PURCHASE_EVIDENCE",
          });
          throw new RequestFailure(409, "no_purchase_evidence");
        }
        if (!verification.verifiedAt) {
          throw new RequestFailure(503, "revenuecat_invalid_response");
        }
        const entitlementActive = verification.result === "active_entitlement";
        const completed = await dependencies.complete({
          userId,
          claimId,
          verifiedAt: verification.verifiedAt,
          entitlementActive,
          reconciliationResult: verification.result,
        });
        if (!completed) throw new RequestFailure(409, "completion_rejected");
        return response(200, {
          completed: true,
          entitlement_active: entitlementActive,
          reconciliation_result: verification.result,
        });
      }

      if (operation === "fail") {
        const claimId = claimIdFrom(body);
        if (body.error_code !== "RC_SYNC_FAILED") {
          throw new RequestFailure(400, "invalid_error_code");
        }
        const row = await dependencies.getMigration(userId);
        if (!liveClaim(row, userId, claimId, dependencies.now())) {
          throw new RequestFailure(409, "claim_not_live");
        }
        const failed = await dependencies.fail({
          userId,
          claimId,
          errorCode: "RC_SYNC_FAILED",
        });
        if (!failed) throw new RequestFailure(409, "fail_rejected");
        return response(200, { failed: true });
      }

      throw new RequestFailure(400, "invalid_operation");
    } catch (error) {
      if (error instanceof RequestFailure) {
        return response(error.statusCode, { error: error.publicCode });
      }
      console.error("apple migration coordinator failed safely");
      return response(500, { error: "internal_error" });
    }
  };
}

function response(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    },
  });
}
