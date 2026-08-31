export const APPLE_PRODUCTION_URL =
  "https://buy.itunes.apple.com/verifyReceipt";
export const APPLE_SANDBOX_URL =
  "https://sandbox.itunes.apple.com/verifyReceipt";
export const BLDR_IOS_BUNDLE_ID = "com.bldr-fitness.app";
export const LEGACY_APPLE_PRODUCTS = new Set(["MENSAL", "ANUAL"]);

export type AppleTransaction = {
  product_id?: unknown;
  expires_date_ms?: unknown;
  transaction_id?: unknown;
  original_transaction_id?: unknown;
  cancellation_date_ms?: unknown;
  cancellation_date?: unknown;
};

export type AppleReceiptResponse = {
  status?: unknown;
  receipt?: { bundle_id?: unknown; in_app?: unknown };
  latest_receipt_info?: unknown;
};

export type ValidatedAppleSubscription = {
  productId: "MENSAL" | "ANUAL";
  billingPeriod: "monthly" | "annual";
  expirationDate: string;
  transactionId: string;
  originalTransactionId: string;
};

export class RequestFailure extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly publicMessage: string,
  ) {
    super(publicMessage);
  }
}

export function bearerToken(authorization: string | null): string {
  const match = authorization?.match(/^Bearer\s+([^\s]+)$/i);
  if (!match) throw new RequestFailure(401, "Autenticação obrigatória.");
  return match[1];
}

export function assertCanonicalUser(
  authenticatedUserId: string,
  bodyUserId: unknown,
): string {
  if (typeof bodyUserId === "string" && bodyUserId !== authenticatedUserId) {
    throw new RequestFailure(403, "Identidade da requisição não confere.");
  }
  return authenticatedUserId;
}

function transactionsFrom(response: AppleReceiptResponse): AppleTransaction[] {
  const latest = Array.isArray(response.latest_receipt_info)
    ? response.latest_receipt_info
    : [];
  const inApp = Array.isArray(response.receipt?.in_app)
    ? response.receipt.in_app
    : [];
  return [...latest, ...inApp].filter(
    (entry): entry is AppleTransaction =>
      entry !== null && typeof entry === "object",
  );
}

function parseExpiration(value: unknown): number | null {
  if (typeof value !== "string" && typeof value !== "number") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

export function validateAppleSubscription(
  response: AppleReceiptResponse,
  requestedProductId: unknown,
  nowMs = Date.now(),
): ValidatedAppleSubscription {
  if (response.status !== 0) {
    throw new RequestFailure(422, "A Apple não validou este recibo.");
  }
  if (response.receipt?.bundle_id !== BLDR_IOS_BUNDLE_ID) {
    throw new RequestFailure(422, "O recibo não pertence ao BLDR.");
  }
  if (
    typeof requestedProductId !== "string" ||
    !LEGACY_APPLE_PRODUCTS.has(requestedProductId)
  ) {
    throw new RequestFailure(422, "Produto Apple não reconhecido.");
  }

  const candidates = transactionsFrom(response)
    .filter((transaction) => transaction.product_id === requestedProductId)
    .map((transaction) => ({
      transaction,
      expirationMs: parseExpiration(transaction.expires_date_ms),
    }))
    .filter(
      (
        entry,
      ): entry is { transaction: AppleTransaction; expirationMs: number } =>
        entry.expirationMs !== null,
    )
    .sort((a, b) => b.expirationMs - a.expirationMs);

  const latest = candidates[0];
  if (!latest) {
    throw new RequestFailure(422, "Recibo sem assinatura compatível.");
  }
  if (
    latest.transaction.cancellation_date_ms != null ||
    latest.transaction.cancellation_date != null
  ) {
    throw new RequestFailure(422, "A assinatura foi revogada ou reembolsada.");
  }
  if (latest.expirationMs <= nowMs) {
    throw new RequestFailure(422, "A assinatura Apple está expirada.");
  }
  if (
    typeof latest.transaction.transaction_id !== "string" ||
    latest.transaction.transaction_id.length === 0 ||
    typeof latest.transaction.original_transaction_id !== "string" ||
    latest.transaction.original_transaction_id.length === 0
  ) {
    throw new RequestFailure(422, "Recibo sem identificadores de transação.");
  }

  const productId = requestedProductId as "MENSAL" | "ANUAL";
  return {
    productId,
    billingPeriod: productId === "ANUAL" ? "annual" : "monthly",
    expirationDate: new Date(latest.expirationMs).toISOString(),
    transactionId: latest.transaction.transaction_id,
    originalTransactionId: latest.transaction.original_transaction_id,
  };
}

export async function verifyWithApple(
  receiptData: string,
  sharedSecret: string,
  fetcher: typeof fetch,
): Promise<AppleReceiptResponse> {
  const request = async (url: string): Promise<AppleReceiptResponse> => {
    const response = await fetcher(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        "receipt-data": receiptData,
        password: sharedSecret,
        "exclude-old-transactions": true,
      }),
    });
    if (!response.ok) {
      throw new RequestFailure(502, "Falha temporária ao consultar a Apple.");
    }
    return await response.json() as AppleReceiptResponse;
  };

  const production = await request(APPLE_PRODUCTION_URL);
  if (production.status === 21007) return await request(APPLE_SANDBOX_URL);
  return production;
}
