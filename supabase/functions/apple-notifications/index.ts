import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Busca as chaves públicas da Apple e retorna um mapa kid → CryptoKey
async function fetchApplePublicKeys(): Promise<Map<string, CryptoKey>> {
  const res = await fetch('https://appleid.apple.com/auth/keys');
  if (!res.ok) throw new Error(`Falha ao buscar chaves Apple: ${res.status}`);
  const { keys } = await res.json();

  const keyMap = new Map<string, CryptoKey>();
  for (const jwk of keys) {
    const key = await crypto.subtle.importKey(
      'jwk',
      jwk,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['verify'],
    );
    keyMap.set(jwk.kid, key);
  }
  return keyMap;
}

// Decodifica e verifica a assinatura do JWT payload enviado pela Apple
async function verifyAppleJwt(token: string): Promise<Record<string, unknown>> {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('JWT malformado');

  const [headerB64, payloadB64, signatureB64] = parts;

  const header = JSON.parse(atob(headerB64.replace(/-/g, '+').replace(/_/g, '/')));
  const payload = JSON.parse(
    new TextDecoder().decode(
      Uint8Array.from(atob(payloadB64.replace(/-/g, '+').replace(/_/g, '/')), (c) => c.charCodeAt(0)),
    ),
  );

  const keys = await fetchApplePublicKeys();
  const key = keys.get(header.kid);
  if (!key) throw new Error(`Chave pública não encontrada para kid: ${header.kid}`);

  const data = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signature = Uint8Array.from(
    atob(signatureB64.replace(/-/g, '+').replace(/_/g, '/')),
    (c) => c.charCodeAt(0),
  );

  const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, signature, data);
  if (!valid) throw new Error('Assinatura JWT inválida');

  return payload;
}

async function deleteUserById(supabaseAdmin: ReturnType<typeof createClient>, userId: string) {
  // Remove todas as sessões ativas antes de deletar
  await supabaseAdmin.auth.admin.signOut(userId, 'global');
  const { error } = await supabaseAdmin.auth.admin.deleteUser(userId);
  if (error) throw new Error(`Erro ao deletar usuário ${userId}: ${error.message}`);
}

serve(async (req) => {
  // A Apple envia POST com Content-Type: application/x-www-form-urlencoded
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  try {
    const body = await req.text();
    const params = new URLSearchParams(body);
    const signedPayload = params.get('payload');

    if (!signedPayload) {
      return new Response(JSON.stringify({ error: 'payload ausente' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Valida a assinatura com a chave pública da Apple antes de confiar no conteúdo
    const jwtPayload = await verifyAppleJwt(signedPayload);
    const events = jwtPayload['events'] as string | undefined;

    if (!events) {
      return new Response(JSON.stringify({ error: 'events ausente no payload' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const eventData = JSON.parse(events) as Record<string, unknown>;
    const eventType = eventData['type'] as string;
    // sub é o Apple User ID que identifica o usuário
    const appleUserId = eventData['sub'] as string;

    console.log(`Apple notification recebida: type=${eventType}, sub=${appleUserId}`);

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Localiza o usuário Supabase pelo provider_id da Apple (o campo sub do token Apple)
    const { data: { users }, error: listError } = await supabaseAdmin.auth.admin.listUsers();
    if (listError) throw new Error(`Erro ao listar usuários: ${listError.message}`);

    const targetUser = users.find((u) =>
      u.app_metadata?.provider === 'apple' &&
      u.app_metadata?.providers?.includes('apple') &&
      // O Supabase armazena o sub da Apple em identities
      u.identities?.some((identity) =>
        identity.provider === 'apple' && identity.identity_data?.sub === appleUserId
      )
    );

    if (!targetUser) {
      // Usuário não encontrado — pode já ter sido deletado; retorna 200 para a Apple não reenviar
      console.log(`Usuário com sub=${appleUserId} não encontrado. Ignorando.`);
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (eventType === 'consent-revoked') {
      // Usuário revogou o app em Configurações → Apple ID → revoga todas as sessões
      await supabaseAdmin.auth.admin.signOut(targetUser.id, 'global');
      console.log(`Sessões revogadas para usuário ${targetUser.id}`);
    } else if (eventType === 'account-delete') {
      // Apple ID deletada → remove a conta inteiramente
      await deleteUserById(supabaseAdmin, targetUser.id);
      console.log(`Usuário ${targetUser.id} deletado por account-delete da Apple`);
    } else {
      console.log(`Tipo de evento não tratado: ${eventType}`);
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Erro ao processar notificação Apple:', err.message);
    // Retorna 500 para a Apple reenviar a notificação depois
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
