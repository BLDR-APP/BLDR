# Comunidade v2 — Levantamento (somente leitura)

Figma: arquivo `UAUhuDakeseJsEfb8ynv5h`, página `0:1`, frames visíveis (440 × 956).
Base: `COMUNIDADE_SPEC.md` (fases 1–8, já implementadas em grande parte), código
atual em `lib/features/community/` e `lib/features/club/` e migrations em
`supabase/migrations/`.

Legenda: **[V]** = só apresentação, com o dado que já existe (origem citada).
**[F]** = depende de código, dado ou banco que ainda não existe.
**[–]** = existe hoje e **falta** no mockup (decidir se some ou se fica).

> Nada aqui foi implementado. Migrations propostas são **esboços**, não criados.

---

## 0. Mapa do código atual

| Área | Tela/widget atual | Dados |
|---|---|---|
| Hub da comunidade | `club/presentation/bldr_club/comunidade_screen.dart` (abas, feed, squads) | `CommunityFeedRepository` (`community/domain`) |
| Feed / post | cards dentro de `comunidade_screen.dart` | `community_feed`, `community_reactions`, `community_comments` (baseline 20260829000001–3) |
| Comentários | `community/presentation/community_comments_sheet.dart` | `fetchComments/addComment/editComment/deleteComment`; threads (000010) |
| Criar post | `community/presentation/create_post_screen.dart` + `widgets/wearable_*` | `createPost`, `uploadCommunityPhoto`, `fetchRecentWorkouts`, `fetchWearableActivities`, `detectRecentWearableActivity` |
| Ver treino / copiar | `community/presentation/workout_detail_sheet.dart` | `fetchWorkoutExercises`, `copyWorkout` (RPC `copy_workout_to_template`) |
| Seguir | botão no card | `followUser/unfollowUser`, `community_follows` (000009) |
| Segurança do card | menu do card | `blockUser`, `reportUser`, `deletePost` (000019) |
| Busca de perfil | `community_profile_search_screen.dart` | `searchProfiles`, `searchPublicPosts` |
| Perfil público | (via `ChallengeRepository.publicProfile`) | `PublicClubProfile` |
| Posts privados | aba/fluxo atual | `fetchPrivatePosts`, `visibility = 'private'` |
| Ranking | `community/presentation/ranking_screen.dart` | `fetchRanking(category: volume/consistency/progression, period: week/month/all)`; RPCs (000006, 20260815) |
| Squads (Arena) | `arena_details_screen`, `create_arena_screen`, `join_squad_sheet`, `squad_settings_screen`, `create_checkin_sheet`, `arena_history_sheet` | `ArenaRepository` (`bldr_club.arenas`, `arena_participants`, `tribunal_posts`) |
| Chat do squad | dentro da arena | `tribunal_posts` com `status = 'chat'` |
| Feed do squad | `fetchSquadFeed` | `community_feed.visibility = 'squad'` + `squad_id` (000015) |
| Duelos | `competition_hub_screen` | `myDuels`, `sendDuelInvite`, `respondDuel`, `checkActiveDuel` |
| Desafios coletivos | `competition_hub_screen`, `create_collective_challenge_screen`, `collective_challenge_detail_screen` | `ChallengeRepository` (`bldr_club.collective_*`, 000027) |
| Notificações | `club/presentation/bldr_club/notifications_screen.dart` | `notifications`, `markAllNotificationsRead`, `markNotificationRead`; push (20260809000001, 000011, 000016) |
| Privacidade | `profile/presentation/privacy_screen.dart` | `PrivacySettings` (`photoVisibility`, `feedVisible`, `reactionsEnabled`, `rankingVisible`) |

---

## 1. Hub (Explorar · Seguindo · Squads)

### 4:2 — Hub / Explorar
Tela atual: `comunidade_screen.dart`, aba Explorar.
- [V] Título "Comunidade" e abas Explorar/Seguindo/Squads (as abas já existem).
- [V] Ícones de cabeçalho: cadeado → posts privados, alvo → desafios, troféu → ranking, sino → notificações (as 4 telas existem).
- [V] Card de post: avatar com iniciais, nome, selo CLUB (`isClubMember`), meta "agora · cidade", texto, bloco tipado (TREINO CONCLUÍDO · título · volume/séries/PRs · "Ver treino"), reações, comentários e compartilhar. Origem: `CommunityPost` + `CommunityPostPayload`.
- [V] Botão SEGUIR (`followUser`).
- [V/F] Cidade na meta ("Belo Horizonte"): só [V] se o perfil já tiver cidade. **Verificar** `profiles`; se não houver campo, vira [F] ou sai.
- [V] Post de atividade importada (Apple Watch · distância/duração/FC): `payload` de wearable.
- [V] FAB `pencil-plus` → criar post.
- [–] Se hoje houver banner, anúncios/eventos (`community_service.fetchAnnouncements/fetchEvents`) ou busca no topo do hub, isso não aparece no mockup. Busca de perfil some do topo (decisão D1).

### 4:57 — Hub / Seguindo
- [V] Mesmo card, filtrado: `fetchFollowingFeed`.
- [V] Post com foto ("PHOTO LABEL"): `photo_url`.
- [–] Sem estado vazio desenhado ("siga pessoas"). Usar o atual, com visual v2.

### 4:108 — Hub / Squads
- [V] "MEU SQUAD": nome, modo, nº de membros, semana N, avatares (+N): `myActiveSquadArena` + `membersCombined`.
- [V/F] Métricas "treinaram hoje" (6), "ranking" (#2) e "consistência" (94%): "hoje" sai dos check-ins do dia (`tribunal_posts`). **#2** = posição de quem? (do usuário no squad → [V], calculável; do squad entre squads → [F], não existe ranking de squads). **Consistência do squad** → [F] (não existe; fórmula a definir).
- [V] Card "Descobrir Squads" → 107:827.
- [F] "Atividade recente" com eventos ("assumiu a liderança do desafio semanal com 38.420 kg"): não há feed de eventos de squad. O `tribunalFeed` tem check-ins e chat, mas não "mudou de posição".
- [V] CTA "+ CRIAR OU ENTRAR EM UM SQUAD" → 86:827.
- [–] Lista de vários squads (`mySquads`): o mockup mostra só um "Meu squad". Decisão D4.

---

## 2. Ações sobre o post

### 6:8 — Sheet de ações do post (`BldrV2Sheet`)
- [F] Copiar link: não há deep link de post (rota/universal link inexistente).
- [V/F] Ocultar post: não existe "ocultar" por usuário (só bloquear). → [F] (tabela `community_hidden_posts`) ou mapear para "bloquear" (D2).
- [F] "Parar de sugerir este perfil": não existe sugestão personalizada. Some ou vira [F].
- [V] Denunciar: `reportUser`. Falta denunciar **o post** (hoje é o usuário); a tabela de 000019 deve ser conferida.
- [–] Bloquear, excluir (próprio post) e editar: existem hoje e **não aparecem** no sheet. Proposta: manter "Excluir" quando o post é meu e "Bloquear" no lugar de "parar de sugerir".

### 6:90 — Sheet de compartilhar
- [V] "Fora do BLDR": share nativo (`share_plus` já usado no compartilhar treino).
- [F] Copiar link: igual a 6:8 (sem deep link).
- [F] "Enviar para alguém" e lista de contatos recentes com botão ENVIAR: é o post privado direcionado. Hoje `visibility = 'private'` significa "só eu". **Não existe** destinatário. Ver 121:827.
- [V/F] "Compartilhar no squad": criar post `visibility='squad'` com referência ao original. Repost/referência não existe → [F] leve (`shared_from_id`).

### 22:148 — Ver treino (sheet)
- [V] Volume, séries, PRs e lista de exercícios: `workout_detail_sheet.dart` (`fetchWorkoutExercises`).
- [V] CTA "Adicionar aos meus treinos": `copyWorkout`. Migrar o visual para `BldrV2Sheet`.

### 22:285 — Ver atividade (sheet)
- [V] Métricas e detalhes (pace, FC, kcal) do `payload` de wearable. Nenhuma tela atual dedicada: nova apresentação, mesmos dados.

### 22:419 — Ver evolução do PR (sheet)
- [V/F] 1RM estimado, PR anterior, delta e histórico: o post `pr_beaten` traz o PR atual. Histórico e PR anterior de **outro usuário** precisam de leitura de `personal_records`/série de outro user_id. A RLS hoje provavelmente impede → [F] (RPC `public_pr_history(user, exercise)` respeitando privacidade).

---

## 3. Criar publicação

### 32:202 — Criar post / vazio
Tela atual: `create_post_screen.dart` (tela cheia). Mockup: **sheet**.
- [V] Autor (avatar, nome, @handle), prompt, 4 tipos (Treino · Atividade · Wearable · Foto), visibilidade e PUBLICAR.
- [V] Visibilidade "Comunidade" (public). Opções no seletor: Comunidade / Squad / Só eu (todas existem).
- [–] Se hoje o editor tiver template visual, música etc., some. Conferir no editor.

### 32:234 — Escolher treino
- [V] Lista de treinos recentes: `fetchRecentWorkouts`.

### 32:287 — Escolher atividade (~60 modalidades)
- [F] Post de atividade **manual** (sem wearable) com modalidade: hoje a atividade vem do wearable. Há uma lista de modalidades no check-in (`create_checkin_sheet`) e as modalidades estão registradas como fase futura (B12). Criar uma atividade manual exige um formulário (duração, distância?) que **não está desenhado**. Decisão D3.

### 32:343 — Wearable (origem)
- [V] WHOOP e Apple Watch: integrações existem (`fetchWearableActivities`).
- [F] Garmin: integração inexistente (igual à Home). Fica oculto/"em breve".
- [V] Nota "últimos 10 registros": `limit` do datasource.

### 32:373 — Foto
- [V] Galeria/câmera + `uploadCommunityPhoto`.

### 42:452 · 42:642 · 42:1022 — Selecionado (treino / atividade / wearable)
- [V] Card "SELECIONADO" com ALTERAR e stats (do recent workout ou do payload).

### 42:832 — WHOOP / registros recentes
- [V] Lista com strain, meta1/meta2, selo DATA BY WHOOP e wordmark (manter tamanhos mínimos do `bldr_whoop_card.dart`).
- [V] "Trocar" wearable: alternar entre fontes conectadas.

### 46:602 · 46:855 · 50:702 · 50:961 — Foto no card / foto anexada
- [F leve] Post de treino/wearable **com foto anexada**: conferir se `createPost` aceita payload + `photo_url` juntos. Se a coluna existe e a UI hoje separa, é [V]. Caso contrário, é um ajuste no repository (sem migração).
- [V] Ações TROCAR e REMOVER e o "+" de mais fotos. **Múltiplas fotos** ("1 foto" + "+") → [F]: hoje há um `photo_url` único. Decisão D5.

---

## 4. Detalhe do post e perfil social

### 52:802 — Publicação (detalhe)
- [F leve] Tela de detalhe de post em rota própria: hoje os comentários são um sheet sobre o feed. É presentation, mas **cria rota** (regra: avisar). Os dados existem (post e `fetchComments`).
- [V] Comentários com resposta ("Responder"): threads (000010).
- [V] Campo "Adicionar comentário" e enviar.
- [V] Ícone de copiar ao lado do nome ("COPY"): provavelmente copiar o treino (`copyWorkout`).

### 56:855 — Perfil social (@pedrolima)
- [V] Avatar, nome, verificado (CLUB), @handle, SEGUIR e publicações do usuário.
- [V/F] "NÍVEL 5 · #8 RANKING": nível vem do XP (dependência B10), ranking de `myRankingEntry`/RPC.
- [V/F] Bio "Treino, corrida e HYROX" e cidade: verificar campos em `profiles` (D6).
- [F] Contadores de seguidores e seguindo: a tabela `community_follows` existe, falta RPC de contagem (fácil, sem migração se a RLS permitir count).
- [V] Performance (treinos, PRs, semanas ativas): `PublicClubProfile` (conferir os campos; semanas ativas pode faltar → [F]).
- [F] Chips de modalidades (Musculação/Corrida/HYROX): não existe "modalidades do perfil".
- [V] Conquistas com "Ver conquistas": feature `achievements` existe; precisa expor as de **outro** usuário (conferir RLS).
- [–] Duelar/desafiar (`sendDuelInvite`) a partir do perfil: existe hoje e não aparece. Decisão D7 (duelos sumiram do mockup inteiro).

---

## 5. Squads

### 86:827 — Sheet "Criar ou entrar"
- [V] "Tenho um código de convite" (`findArenaByCode` + `joinSquadWithQuota`) e "Criar novo squad".

### 86:842 — Novo squad
- [V] Nome, modo (SURVIVOR · ALFA · ROADRUNNER · HUSTLE) e duração (7/15/30 dias): `createSquadWithQuota(gameMode)`. `hustle` já existe (`create_checkin_sheet`, `arena_history_sheet`).
- [F] "Aposta do squad (opcional)": não há coluna. Migração simples (`arenas.stake text`).
- [V/F] Duração de 7/15/30: conferir se `arenas` tem duração/`ends_at` (há cron de deadline, 20260505000000 → provável [V]).
- [–] Validação por foto e votação ("tribunal") e limites FREE mostrados hoje na tela de criar: não aparecem. O limite FREE precisa continuar visível de alguma forma (D8).

### 86:878 — Squad / visão geral
- [V] Cabeçalho (nome, modo, membros, semana N), avatares, #ranking (posição do usuário no squad), "6/8 hoje".
- [F] Consistência % do squad (igual ao hub).
- [V] "3 dias restantes": prazo da arena.
- [F] "Meta de hoje" customizável (vem de 98:1484).
- [V/F] Atividade do squad: check-in e treino concluído [V] (`tribunalFeed`, squad feed); "assumiu o #1" [F] (evento de troca de posição).
- [V] CHAT e CHECK-IN (`submitCheckin`, `todayCheckinStatus`).
- [V] Compartilhar squad → 117:842.
- [–] Votação de prova por foto (tribunal) e histórico (`arenaHistory`): não aparecem. Decisão D8.

### 87:827 — Squad / feed
- [V] Feed do squad (`fetchSquadFeed` + check-ins), com tipos TREINO CONCLUÍDO / CHECK-IN / NOVO LÍDER ([F] para "novo líder").

### 87:884 — Squad / ranking
- [V] Ranking da semana do squad por dias treinados (`participantsCombined`), com "Você" destacado.

### 96:830 — Chat do squad
- [V] Mensagens (`tribunal_posts status='chat'`), hora e enviar.
- [F] "+" anexo no chat: hoje o chat é só texto. Some ou vira [F].
- [V] Aviso "visíveis apenas para membros" (RLS de arena).

### 86:919 + 98:1291…98:1653 — Configurações do squad (sheets)
- [V] Informações (nome) via `updateArena`; [F] aposta (coluna nova).
- [F] Visibilidade Privado/Público: não há squad público (hoje é sempre por código). Coluna `arenas.visibility` + descoberta.
- [V] Membros com papel (admin/membro) e menu `•••` (`kickMember`). "Convidar membros" = compartilhar o código [V].
- [F] Meta diária (texto livre): coluna nova `arenas.daily_goal text`.
- [V] Regras de pontuação: texto informativo por modo, só leitura ("o modo não pode ser alterado").
- [V] Sair (`leaveArena`) e encerrar (`deleteArenaTotally`) com `BldrV2ConfirmDialog` destrutivo.

### 107:827 — Descobrir squads públicos
- [F] Inteiro: busca, filtro por modo, cards com modalidades, nº de membros, consistência. Depende de squad público, modalidades do squad e métricas agregadas.

### 107:871 — Squad público / detalhe
- [F] Sobre, "como funciona", top da semana (km), ranking #14 entre squads, ENTRAR. Depende de visibilidade pública, descrição e ranking de squads. ENTRAR = `joinSquadWithQuota` [V].

### 107:917 — Entrar com código (sheet)
- [V] Campo de código + ajuda: `findArenaByCode` / `joinSquadWithQuota`.

### 117:842 — Compartilhar squad (sheet)
- [V] Share nativo com código.
- [F] Card-imagem do squad (rank, nome) e link: sem deep link.

---

## 6. Desafios

### 121:893 — Desafios / ativos
Tela atual: `competition_hub_screen.dart` (duelos + coletivos).
- [V] Desafio em destaque: progresso X/Y dias, dias restantes, participantes, minha posição (`collectiveChallenges`, `myParticipation`, `topContributors`).
- [F] Imagem de capa do desafio: não há coluna nem bucket (ver 121:960).
- [V] "Outros desafios" (grade) e "Próximo a terminar".
- [V] Botão "Criar" (`create_collective_challenge_screen`).
- [–] **Duelos** (convite, aceitar, duelo ativo) somem do mockup. Decisão D7.

### 141:941 — Descobrir (recomendados · em alta · novos)
- [V] "Novos" (ordenar por `created_at`) e "em alta" (por participantes).
- [F] "Recomendados para você": sem motor de recomendação. Pode virar regra simples [V] (ex.: modalidade/métrica que o usuário mais faz) — decisão D9.

### 141:990 — Concluídos
- [V] `pastChallenges` (check, posição final).

### 143:1006 — Detalhe do desafio (sheet)
- [V] Nome, descrição, duração, meta, participantes, "como funciona" e PARTICIPAR (`challengeDetail`, `joinChallenge`). O detalhe completo atual (`collective_challenge_detail_screen`: feed, marcos, comentários, denunciar) **não aparece** no sheet [–] (D10).

### 121:960 → 121:980 → 121:1016 — Criar desafio (3 passos)
- [F] Capa (JPG/PNG): coluna `cover_url` + storage.
- [V] Nome, descrição.
- [V/F] "O que conta": dias ativos, treinos concluídos, distância (BLDR RUN), XP acumulado. Conferir quais métricas `create_collective_challenge` aceita hoje; distância → [F] se não houver.
- [V] Meta numérica + duração.
- [F] Recompensa "300 XP": o desafio não credita XP ao concluir. **Dependência do sistema de XP** (B10/B14).
- [V/F] Público: Público [V]; **Amigos** [F] (seguidores mútuos, não existe filtro); **Squad** [F] (desafio restrito a squad).
- [V] Revisão + PUBLICAR.

---

## 7. Atalhos do cabeçalho

### 121:827 — Posts privados (recebidos · enviados)
- [F] **Muda o conceito**: hoje "privado" = só eu. O mockup é mensagem direta de post (de Marina para mim, com "Responder"). Exige destinatário (`recipient_id`), RLS nova, notificação e resposta. Impacto grande em `community_feed` e na privacidade.

### 121:1041 — Ranking (global · amigos)
- [V] Período semana/mês/geral e métrica volume/consistência/progressão: `ranking_screen.dart` já tem tudo.
- [V] Pódio top 3, "sua posição" e lista com "Você" destacado.
- [F] Variação "↑ 3 posições esta semana": não há snapshot histórico.
- [F] Aba **Amigos**: filtro por quem eu sigo (RPC com join em `community_follows`).
- [V] Regra FREE (top 10, contra 50 no CLUB) continua; o mockup não mostra o bloqueio [–] (D11).

### 121:1128 — Notificações (todas · social · performance)
- [V] Lista, "marcar todas como lidas", ponto de não lida, agrupamento hoje/ontem/esta semana (`notifications`).
- [V/F] Abas Social/Performance: filtro por `type`. Conferir se o `type` já distingue (provável [V] com um mapa no app).
- [V] Ações inline "Ver desafio" / "Ver convite": navegação pelos ids da notificação (conferir payload).
- [F] "Você subiu para #8 no ranking global": não há job que gere essa notificação.

---

## 8. [F] consolidado

### (a) Só app (sem mudança no Supabase)
1. Criar post como sheet (hoje é tela cheia) e Ver atividade em sheet.
2. Detalhe de post em rota própria (52:802) — **rota nova, pedir aprovação**.
3. Treino/wearable + foto no mesmo post (se `createPost` já aceita os dois).
4. Abas Social/Performance nas notificações (mapa `type → aba`).
5. "Recomendados" por regra simples local.
6. Desafios "em alta" e "novos" por ordenação.
7. Configurações do squad em sheets v2 (dados existentes).
8. Ranking do usuário dentro do squad (#2) a partir de `participantsCombined`.

### (b) Supabase (propostas, **não criadas**)
| # | Item | Proposta |
|---|---|---|
| S1 | Aposta e meta diária do squad | `alter table bldr_club.arenas add column stake text, add column daily_goal text;` (update só pelo criador, RLS já existente) |
| S2 | Squad público e descoberta | `arenas.visibility text not null default 'private' check (visibility in ('private','public'))`, `arenas.description text`, `arenas.modalities text[]`; RPC `discover_public_squads(p_query, p_mode)` security definer, só squads `public` |
| S3 | Métricas de squad (consistência, ranking entre squads, km) | view/RPC `squad_stats(arena_id)`: consistência = check-ins válidos ÷ (membros × dias decorridos); ranking por modo |
| S4 | Eventos de squad ("assumiu o #1") | tabela `bldr_club.squad_events(id, arena_id, user_id, kind, data jsonb, created_at)` gravada por trigger no check-in que recalcula o líder; RLS = membros |
| S5 | Anexo no chat | reaproveitar `tribunal_posts.photo_url` com `status='chat'` (pode não precisar de migração; só a RLS do storage) |
| S6 | Post direcionado (posts privados recebidos/enviados) | `community_feed.recipient_id uuid null references auth.users`; `visibility` ganha `'direct'`; policy select `user_id = auth.uid() or recipient_id = auth.uid()`; notificação no insert |
| S7 | Ocultar post | `community_hidden_posts(user_id, post_id, created_at, pk(user_id,post_id))` + filtro nos RPCs do feed |
| S8 | Denunciar post | conferir 000019; se for só usuário: `community_reports.post_id uuid null` |
| S9 | Repost para squad | `community_feed.shared_from_id uuid null references community_feed(id) on delete set null` |
| S10 | Múltiplas fotos | `community_feed.photo_urls text[]` (manter `photo_url` para compatibilidade) |
| S11 | Contadores de seguidores | RPC `follow_counts(p_user)` security definer (respeita bloqueio) |
| S12 | Perfil social (bio, cidade, modalidades) | colunas em `profiles` (`bio text`, `city text`, `modalities text[]`) — **conferir antes, pode já existir** |
| S13 | Histórico de PR de outro usuário | RPC `public_pr_history(p_user, p_exercise)` respeitando `PrivacySettings.feedVisible` |
| S14 | Capa de desafio | `collective_challenges.cover_url text` + bucket `challenge-covers` (insert pelo criador) |
| S15 | Público do desafio (amigos/squad) | `collective_challenges.audience text check in ('public','friends','squad')`, `squad_id uuid null`; join valida audiência |
| S16 | Recompensa em XP | `collective_challenges.reward_xp int` + crédito ao concluir **via função do servidor** (ver §9) |
| S17 | Ranking: amigos e variação de posição | RPC com `p_scope 'global'|'friends'`; tabela `ranking_snapshots(user_id, category, period, week_start, position)` por cron semanal |
| S18 | Notificação "subiu no ranking" | gerada pelo cron de S17 |
| S19 | Deep link de post/squad | sem banco; precisa de domínio + universal links (iOS/Android) e rota — **infra fora do app** |
| S20 | Métrica distância (BLDR RUN) em desafio | estender `create_collective_challenge`/progress para distância |

---

## 9. Dependências

**Sistema de XP (B10 · B14 · B15)**
- Nível no perfil (56:855) e "XP acumulado" como métrica de desafio e de modo ALFA dependem da fonte única de XP (B10, adiada).
- Recompensa de desafio (S16) **não pode** usar `add_xp_to_user` enquanto ele aceitar qualquer usuário (B14). Crédito só por função `security definer` que use `auth.uid()`/validação de conclusão.
- `check_weekly_goal` conta qualquer `xp_events` como treino (B15): afeta consistência/"dias ativos" se a métrica de squad ou desafio usar `xp_events`. Usar `workout_sessions`/check-ins como fonte.
- Ranking por progressão/consistência: conferir se as RPCs já leem XP.

**Chave service_role vazada (B13, URGENTE)**
- Toda notificação nova (S6, S17/S18, eventos de squad S4, convites) passa pelo webhook/trigger de notificação. O trigger `tribunal-notification` tem a `service_role` em texto puro. **Nenhuma notificação nova antes de B13** (Vault + nova `sb_secret_` + revogar as legadas).
- O chat e a votação do squad usam `tribunal_posts` → o mesmo trigger. Qualquer mudança em S5 espera B13.

**Club no banco (B16)**
- A cota de squad no servidor (`squad_free_club_limits`) usa só o RevenueCat, mais estrito que `ResolveClubAccess`. Squads públicos, desafios e limites novos herdam essa divergência.

---

## 10. Regras FREE/CLUB atuais

| Feature | FREE | CLUB | Onde |
|---|---|---|---|
| Feed, curtir, comentar, seguir, postar | sim | sim (selo CLUB no card) | sem gate em `community/` |
| Criar squad | 2 por mês (cota monotônica) | ilimitado | `create_arena_screen` + RPC `create_squad_with_quota` (`v_limit 2`) |
| Entrar em squad | 5 por mês (sair não devolve) | ilimitado | `join_squad_sheet` + RPC `join_squad_with_quota` (`v_limit 5`) |
| Ranking | top 10 + sua posição | top 50 | `ranking_screen` (`limit 10/50`) |
| Duelos / desafios coletivos | conferir: o gate fica no hub do Club (`bldr_club_screen`) | sim | — |
| Autoridade CLUB | app: `ResolveClubAccess`; banco: só RevenueCat (B16) | | |

O mockup não mostra nenhum cadeado nem paywall. Os pontos de gate atuais precisam de um lugar no visual v2 (D8/D11).

---

## 11. Ordem sugerida

1. **B13** (chave service_role) — pré-requisito de tudo que notifica.
2. **[V] puro**: hub (Explorar/Seguindo), card de post, sheets de ações/compartilhar (só o que existe), ver treino/atividade, criar post em sheet com os 4 tipos (sem atividade manual nem Garmin), ranking v2 (sem amigos/variação), notificações v2 (abas por `type`).
3. **Squads [V]**: hub Squads, criar/entrar, visão geral/feed/ranking/chat, configurações (sem aposta, visibilidade e meta).
4. **Desafios [V]**: ativos/descobrir/concluídos/detalhe, criar em 3 passos (sem capa, recompensa e audiência).
5. **Banco, lote 1 (baixo risco)**: S1, S7, S8, S9, S11, S12, S14 → completa as configurações, ações do post, perfil e capa.
6. **Perfil social e detalhe do post** (rota nova, após aprovação).
7. **Banco, lote 2**: S2/S3/S4 (squads públicos e métricas) → 107:827 e 107:871.
8. **Depois de B10/B14**: S16 (recompensa XP), nível, métrica XP.
9. **Maior impacto**: S6 (posts diretos), S17/S18 (snapshots de ranking), S19 (deep links).

---

## 12. Decisões (respondidas em 17/11/2026)

- **D1** Busca de perfil/posts fica: ícone de busca no cabeçalho junto dos outros atalhos.
- **D2** Menu do post: "Bloquear" (existe) no lugar de "Ocultar" e "Parar de sugerir"; "Excluir" e "Editar" quando o post é meu; "Denunciar" continua (S8 no lote 1). S7 sai do plano.
- **D3** Só wearable por enquanto. Atividade manual com modalidades → backlog (B12).
- **D4** "Meu squad" em destaque; com mais de um, lista "Meus squads" abaixo (`mySquads`).
- **D5** Uma foto por post. Múltiplas fotos (S10) → backlog.
- **D6** Bio/cidade/modalidades: mostrar se já existirem no perfil; senão, ocultar agora (entram com S12 no lote 1).
- **D7** Duelos descontinuados: remover todos os pontos de entrada da interface (ranking, perfil, hub do Club, notificações de convite), sem apagar tabelas nem dados. Limpeza de código e tabelas registrada no backlog (B17).
- **D8** Tribunal (prova por foto + votação) e histórico da arena acessíveis na visão geral do squad; avisos de cota FREE nos sheets de criar e entrar.
- **D9** "Recomendados" por regra simples no app.
- **D10** Detalhe do desafio em sheet + "Ver tudo", que abre a tela completa atual.
- **D11** Ranking FREE: top 10 + card com cadeado ("Veja o top 50 no Club") abrindo o paywall. Cotas de squad nos sheets de criar/entrar.
- **D12** Posts privados continuam "Só eu" nesta fase. Mensagem direta (S6) → backlog; 121:827 fica fora do escopo.
- **D13** Fórmula de consistência de S3 aprovada como proposta, para o lote 2.

**Ordem aprovada:** B13 primeiro (plano e SQL do trigger apresentados antes de aplicar); depois o [V] por áreas, começando por hub + card de post + sheets de ações.

**Precisão:** na implementação, cada tela é lida por partes (`get_metadata` + `get_design_context` por seção). Nenhuma tela é implementada só pelo screenshot (muitos frames deste levantamento foram lidos só por screenshot).
