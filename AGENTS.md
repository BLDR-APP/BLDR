# BLDR Fitness — Regras do Projeto

App Flutter (fitness) em **Clean Architecture por features**. Antes de mexer em
qualquer coisa, consulte:

- **[ESTRUTURA.md](ESTRUTURA.md)** — onde está cada tela/camada e o padrão de
código (leia primeiro).
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — decisões, fases da migração e
dívidas conhecidas.
- - **[docs/redesign/DESIGN_[SYSTEM.md](http://SYSTEM.md)](docs/redesign/DESIGN_[SYSTEM.md](http://SYSTEM.md))** — tokens e
    componentes visuais. Implementados em `lib/theme/bldr_tokens.dart` e
    `lib/widgets/bldr_components.dart`. Telas devem compor a partir deles.
  - **[docs/redesign/REDESIGN_[SPEC.md](http://SPEC.md)](docs/redesign/REDESIGN_[SPEC.md](http://SPEC.md))** — mudanças
    tela a tela. Itens [V] são visuais; [F] dependem de código ainda não escrito.
  - **[docs/redesign/BACKLOG_[FUNCIONAL.md](http://FUNCIONAL.md)](docs/redesign/BACKLOG_[FUNCIONAL.md](http://FUNCIONAL.md))** —
    fase 2, pós-visual.
  - **[docs/redesign/HAVOK_[SPEC.md](http://SPEC.md)](docs/redesign/HAVOK_[SPEC.md](http://SPEC.md))** — HAVOK como
    agente: camadas, localização, limites de segurança.
  > **Redesign em andamento:** mudanças visuais são presentation-only. Nenhum item
  > [V] toca `domain/` ou `data/`, altera assinatura de use case ou muda rota.

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

