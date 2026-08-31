# Comunidade — status da Fase 4

Data: 2026-08-29. Este documento registra implementação e bloqueadores; não é
prova do estado do Supabase. Nenhuma migration desta fase foi aplicada.

## Implementado no app

- Explorar continua exibindo todos os posts públicos; Seguindo usa o social
  graph proposto em `community_follows`.
- Busca por nome, username e legenda de posts públicos.
- Comentários com raiz + uma resposta, edição/exclusão do autor e moderação
  pelo autor do post.
- Reação única no cliente: tocar no mesmo emoji remove; escolher outro substitui.
- Central de notificações com contador de não lidas no sino e rotas de push da
  Comunidade.
- Área de posts privados acessível pelo cadeado no cabeçalho.
- Snapshot Whoop diário preserva provider e identificador externo; deduplicação
  server-side está proposta, não aplicada.
- Atividades Whoop v2 usam o endpoint de coleção (10 mais recentes) e seleção
  no composer; requer deploy manual da função.
- Publicação em exatamente um squad tem contrato de app e migration revisável
  baseados no schema real exportado em 2026-08-29.
- Garmin possui scaffold OAuth 2.0 e armazenamento server-side sem secrets no
  código; URLs, credenciais e normalização final aguardam aprovação do programa.

## Propostas de banco pendentes de revisão

- `20260829000009`: social graph.
- `20260829000010`: comentários em dois níveis.
- `20260829000011`: eventos de notificação.
- `20260829000012`: uma reação por usuário/post.
- `20260829000013`: deduplicação de atividade wearable.
- `20260829000014`: reação somente em post legível.
- `20260829000015`: vínculo e RLS de posts de squad.
- `20260829000016`: webhook sem JWT service_role embutido.
- `20260829000017`: armazenamento server-side de tokens Garmin.

Aplicar apenas após revisar dependências, dados existentes, RLS com dois usuários
`authenticated`, webhook e rollback. Service-role não comprova RLS.

## Bloqueadores e divergências explícitas

- **Squad:** schema real confirmado. Falta revisar/aplicar a migration 15 e
  validar RLS com membro ativo, não membro e autor autenticados.
- **Apple Health:** o canal nativo atual lê FC e calorias, mas não expõe a lista
  de `HKWorkout`. Seleção de atividade exige ampliar o canal e permissões.
- **Whoop:** acesso a workouts confirmado; função `whoop-workouts` preparada
  contra a API v2. Falta deploy e teste com uma conta conectada.
- **Garmin:** scaffold preparado. Aguarda cadastro para preencher secrets e URLs
  oficiais liberadas pelo Developer Program. Nunca hardcode.
- **PR:** função real exportada confirma posts `workout_completed` e `pr_beaten`;
  não criar outro emissor.
- **Segurança urgente:** o inventário expôs uma chave service_role dentro de dois
  triggers. Rotacionar/revogar a chave, substituir os dois webhooks por segredo
  dedicado e remover cópias do CSV antes de compartilhar.
- **Streak:** `GetCurrentStreak` é a fonte canônica, mas os dias que constituem
  marcos publicáveis não estão definidos. Confirmar a lista antes da automação.
