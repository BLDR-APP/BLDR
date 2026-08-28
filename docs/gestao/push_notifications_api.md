# API de Push Notifications — BLDR

## Endpoint

```
POST https://{SUPABASE_URL}/functions/v1/send-push
```

Substitua `{SUPABASE_URL}` pela URL do projeto Supabase BLDR (Settings → API → Project URL).

## Autenticação

```
Authorization: Bearer {GESTAO_WEBHOOK_SECRET}
```

`GESTAO_WEBHOOK_SECRET` deve ser gerado com `openssl rand -hex 32` e inserido em:
- **Supabase BLDR** → Settings → Edge Functions → Secrets → `GESTAO_WEBHOOK_SECRET`
- **Gestão** (Lovable) → variável de ambiente ou secret equivalente

## Secrets necessários no Supabase BLDR

| Secret | Como obter |
|--------|-----------|
| `FIREBASE_PROJECT_ID` | Firebase Console → Configurações → ID do projeto |
| `FIREBASE_CLIENT_EMAIL` | Firebase Console → Configurações → Contas de serviço → Gerar chave privada → campo `client_email` |
| `FIREBASE_PRIVATE_KEY` | Mesmo JSON → campo `private_key` (incluir `\n` literais) |
| `GESTAO_WEBHOOK_SECRET` | `openssl rand -hex 32` |

## Exemplos de payload

### Broadcast para todos

```json
{
  "title": "Nova operação!",
  "body": "Complete 5 treinos e ganhe 2.000 XP",
  "type": "challenge",
  "action_data": {},
  "target": { "mode": "all" }
}
```

### Segmento: membros do Club com streak ativo

```json
{
  "title": "Não quebre o streak!",
  "body": "Você ainda não treinou hoje",
  "type": "streak",
  "action_data": {},
  "target": {
    "mode": "segment",
    "segment": { "is_club_member": true, "min_streak": 3 }
  }
}
```

### Segmento: somente iOS

```json
{
  "title": "Novidade no BLDR!",
  "body": "Confira o que há de novo",
  "type": "info",
  "action_data": {},
  "target": {
    "mode": "segment",
    "segment": { "platform": "ios" }
  }
}
```

### Usuário específico

```json
{
  "title": "Seu duelo começa em 1 hora!",
  "body": "Prepare-se para o desafio",
  "type": "duel_invite",
  "action_data": { "duel_id": "uuid-aqui" },
  "target": { "mode": "user", "user_id": "uuid-aqui" }
}
```

## Resposta

```json
{
  "sent": 1234,
  "failed": 12,
  "invalid_tokens_removed": 12
}
```

Tokens inválidos (dispositivos desinstalados) são removidos automaticamente do banco.

## Tipos de notificação e navegação no app

| `type` | Onde abre no app |
|--------|-----------------|
| `duel_invite` | Tela da Comunidade (com `duel_id` em arguments) |
| `ranking` | Ranking do BLDR Club |
| `challenge` | Comunidade |
| `streak` | Dashboard |
| `level_up` | Perfil |
| `reaction` | Central de notificações |
| `new_member` | Central de notificações |
| (outros) | Central de notificações |

## Campos de segmentação disponíveis

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `is_club_member` | boolean | Filtrar por membros do BLDR Club |
| `min_streak` | int | Mínimo de treinos nos últimos 60 dias |
| `platform` | `"ios"` \| `"android"` \| `"all"` | Plataforma do dispositivo |

## Histórico

Cada envio é registrado automaticamente em `push_notifications_log` (visível apenas via service role — o app Flutter não acessa esta tabela).
