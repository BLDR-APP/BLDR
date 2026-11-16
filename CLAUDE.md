# BLDR Fitness — Regras do Projeto

App Flutter (fitness) em **Clean Architecture por features**. Antes de mexer em
qualquer coisa, consulte:

- **[ESTRUTURA.md](ESTRUTURA.md)** — onde está cada tela/camada e o padrão de
código (leia primeiro).
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — decisões, fases da migração e
dívidas conhecidas.
- **[docs/redesign/DESIGN_SYSTEM.md](docs/redesign/DESIGN_SYSTEM.md)** — tokens e
  componentes visuais da fase 1. Implementados em `lib/theme/bldr_tokens.dart` e
  `lib/design_system/bldr_components.dart`. Telas devem compor a partir deles.
- **[docs/redesign/REDESIGN_SPEC.md](docs/redesign/REDESIGN_SPEC.md)** — mudanças
  tela a tela. Itens [V] são visuais; [F] dependem de código ainda não escrito.
- **[docs/redesign/BACKLOG_FUNCIONAL.md](docs/redesign/BACKLOG_FUNCIONAL.md)** —
  fase 2, pós-visual.
- **[docs/redesign/HAVOK_SPEC.md](docs/redesign/HAVOK_SPEC.md)** — HAVOK como
  agente: camadas, localização, limites de segurança.

> **Redesign em andamento:** mudanças visuais são presentation-only. Nenhum item
> [V] toca `domain/` ou `data/`, altera assinatura de use case ou muda rota.

## Rebranding v2 — Figma

Os mockups do Figma são a **fonte da verdade visual**: a implementação deve
ficar igual ao desenhado.

- Arquivo: `https://www.figma.com/design/Bn5NBPkg7Yr1shm5F7vmb0/Home`
  (fileKey `Bn5NBPkg7Yr1shm5F7vmb0`).
- Ler cada estado pelo MCP do Figma (`get_design_context` + `get_screenshot`),
  um node por vez. **Não** usar código de plugins de exportação para Flutter
  (layout absoluto, cores fixas, sem dados, perde elementos).

### Precedência

Em telas com mockup no Figma, **o mockup vence o DESIGN_SYSTEM.md e o
REDESIGN_SPEC.md**. Não "corrigir" o mockup para seguir regras da fase 1 — ele
as contradiz de propósito: cards sólidos em vez de glass (G2), peso 700 (G7),
cores oficiais do WHOOP nos anéis (G4), CTAs em caixa alta (G8), fundo
`#050505` (G1). Telas sem mockup continuam seguindo a fase 1.

Exceções ao Figma:

- **Guidelines do WHOOP:** selo "DATA BY WHOOP" e wordmark mantêm os tamanhos
  mínimos já implementados em `bldr_whoop_card.dart`. Sem `colorBlendMode`.
- **Responsividade:** em 440 px de largura fica idêntico ao frame; em telas
  menores, adapta proporcionalmente, sem overflow e sem esconder elementos.

### Escala tipográfica (v2)

- Degraus fixos em `BldrTextV2` (`BldrTextV2.scale`): **11 · 12 · 13 · 15 · 17 ·
  20 · 24 · 28 · 32**, mínimo 11. Cada tamanho do mockup vai para o degrau mais
  próximo (empate sobe); pesos, cores e espaçamento entre letras seguem o
  mockup. Nunca usar tamanhos soltos em telas v2.
- Sem overflow, corte ou sobreposição em 320 e 440 px e com `textScaler` 1,3;
  textos longos com reticências. Detalhes e exceções em
  `docs/redesign/TREINOS_V2.md`.

### Ícones (v2)

- Ícones: sempre Tabler Icons, conforme o nome da camada no Figma. Não usar
  ícones do Material em telas do rebranding.

### Regras

1. **Presentation-only**, como no resto do redesign. Valores dos mockups
   ("71 kg", "Push A", "Bom dia") são exemplos — ligar ao dado que o widget já
   recebe.
2. **Tokens do Figma são adicionados** em `lib/theme/bldr_tokens.dart`, numa
   seção própria (v2). Não sobrescrever os da fase 1: telas ainda não
   redesenhadas não podem mudar. Nenhum `Color(0x…)` dentro de widgets.
3. Elementos repetidos (card sólido, chip de stat, barra, anel, CTA com borda)
   viram componentes em `lib/design_system/`.
4. Textos novos ou alterados vão para os `.arb`.
5. **Mockup que exige funcionalidade inexistente → parar e avisar.** Listar o
   que falta e esperar aprovação; não implementar por conta própria.
6. Ao fim de cada estado: validação obrigatória (abaixo) + comparação com o
   `get_screenshot` do node.

### Home — estados (frame 440 × 956)

Uma única tela (aba 0 do `dashboard.dart`) com seções que recebem o próprio
estado — não criar uma tela por estado. Reaproveitar `BldrWhoopCard`,
`BldrNavBar` e `BldrBackground`. O efeito de cards empilhados do wearable deve
ser um widget genérico que recebe o card ativo, para o Garmin encaixar depois.

| Seção | Estado | node-id |
|---|---|---|
| Base | Sem insight do Havok | `57:388` |
| Havok | Banner flutuante / card expandido | `57:390` / `57:389` |
| Treino de hoje | Planejado / descanso / sem plano | `57:387` / `57:386` / `57:385` |
| Treino de hoje | Em andamento / concluído | `57:380` / `57:379` |
| Wearable | WHOOP / sem wearable / dados indisponíveis | `57:384` / `57:382` / `57:381` |

Fora do escopo: Garmin (`57:383`, integração não existe) e os frames ocultos
`2:5` e `19:297`.

## Regras inegociáveis

1. **Telas nunca acessam dados diretamente.** Proibido `Supabase.instance`,
  `FirebaseFirestore.instance` ou `XService.instance` em `presentation/`.
   Dados entram via use case/repository: `getIt<UseCase>()`.
2. **Código novo segue o layout de feature**: `lib/features/<x>/{domain,data,presentation}`.
  Queries só em `data/datasources/`; regras de negócio em `domain/`.
3. **Erros são** `Failure` **via** `Result<T>` (`lib/core/errors/`), com mensagem
  pt-BR pronta para a UI. Nada de `throw Exception('...$error')` atravessando camadas.
4. **Imports absolutos**: `package:bldr_fitness/...`. Nunca relativos (`../..`).
5. **Dependência nova → registrar em** `lib/core/di/injection.dart`**.**
6. `lib/services/` é **legado em extinção**: só os repositories podem usá-lo.
  Não adicionar métodos lá para consumo de telas (exceção documentada:
   `UserService` abriga dados de perfil até a feature profile nascer).
7. **Toda feature/regra nova ganha teste de unidade** em `test/features/<x>/`
  com repository fake (exemplos em `test/features/auth/` e `test/features/nutrition/`).
8. Usuário logado: `getIt<GetCurrentUser>()()` / `getIt<AuthRepository>()` —
  nunca `auth.currentUser` do SDK em telas.



## Validação obrigatória antes de encerrar

```bash
dart analyze lib
flutter test test/features
```

Ambos devem passar sem erros novos.

## **Avisos de ambiente**

- Ambiente atual: **PC novo (Xcode 26)** — builda iOS normalmente.

- O Mac antigo (macOS 13 / Xcode 15.2) **não builda iOS**: o projeto usa o formato

  do Xcode 26. Não "consertar" o `project.pbxproj` para abrir lá.

- Sempre abrir `ios/Runner.xcworkspace` — nunca o `.xcodeproj` (com CocoaPods, o

  `.xcodeproj` sozinho não enxerga os Pods e gera erros de `lstat` no pub-cache).

- `ios/Flutter/Generated.xcconfig` é por máquina — não commitar.

- Config de chaves em `dart_defines.dev.json` (nunca hardcode de chave em Dart).

