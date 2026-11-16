# Home v2 — Rebranding (Figma `Bn5NBPkg7Yr1shm5F7vmb0`)

Aba 0 do `dashboard.dart`. Tokens em `lib/theme/bldr_tokens.dart` (seção v2),
componentes em `lib/design_system/bldr_v2_components.dart`.

## Feito
- **Fundo:** `#050505` + glows elípticos do SVG do mockup (`BldrBackground(v2: true)`).
- **Header:** saudação + `fullName` 31/700 + avatar 36; ícone do HAVOK saiu do header.
- **Nível/XP:** pílula com borda, trilho 139 com gradiente, XP compacto no locale ("13,2k / 20k").
- **Chips:** Streak · Treinos/mês · Tempo total (81×78, centralizados).
- **Wearable:** `WearableStack` rolável (arraste horizontal, ciclo, pontos com 2+ cards); cards WHOOP (dados / sincronizando / indisponível), Conectar (sempre o último) e Garmin (só showcase).
- **Treino de hoje:** `BldrTrainCardV2` com 5 estados (planejado, descanso, sem plano, em andamento, concluído) ligados às regras e ações existentes.
- **Grid 2×2:** Peso alvo · Calorias · Macros · 7 dias em tiles sólidos (`BldrTileV2`); "N treinos" corrigido (contava minutos).
- **Havok:** banner flutuante fixo no topo → card expandido (toque); "×" dispensa no dia; "Conversar com Havok" abre `showHavokSheet`.
- **Navbar:** `BldrNavBarV2` (pílula + botão HAVOK) em todas as abas.
- **Fontes:** Inter 300 e 700 (release oficial 4.1) adicionadas ao pubspec.

## Decisões tomadas (divergem do mockup ou do DESIGN_SYSTEM.md)
- Mockup vence a fase 1: cards sólidos, peso 700, CTAs em caixa alta, cores oficiais WHOOP/Garmin.
- "DATA BY WHOOP" mantém tamanho mínimo (texto 9, logo 9) em vez de 4,6 px; sem `colorBlendMode`.
- Card "Dados indisponíveis" sem atribuição WHOOP (nenhum dado exibido).
- Pilha sempre com 3 camadas; 4ª camada (não existe no Figma): offsets 15/10/5/0, recuos 0/3/6/9, `#100F0D`, altura 188 mantida.
- Card Conectar sempre presente → com WHOOP conectado a Home mostra pontos de posição (não aparecem no 57:388).
- Camadas de trás sempre na cor neutra da pilha, inclusive atrás do Garmin.
- Botão Conectar abre Configurações no topo (sem rolagem até Integrações; app não tem tela de dispositivos).
- Navbar sem estado ativo no Figma → ícone ativo em `#D4AF37`.
- Avatar "✦" do HAVOK no header (57:390/57:389) não incluído (esquecido no mockup).
- Headline do insight: fallback para o título fixo do .arb.
- Itens removidos da Home (consultas mantidas): chip de Conquistas, dica de recovery, kcal gastas, selo % do Peso alvo, chama em Calorias, tempo total do 7 dias, botão "Finalizar treino".
- Em andamento mostra só o treino mais recente; arrastar para a esquerda descarta.
- Glyphs ▶ e ↗ trocados por ícones Material (evita emoji no iOS).
- Barras de dia sem treino com altura fixa 10 (mockup varia por ser exemplo).

## Pendente (novas funcionalidades) — registradas no BACKLOG_FUNCIONAL.md
- **Headline do insight:** edge function `gerar-insight-havok` devolver headline curto (≤ 40) + use case repassar.
- **Integração Garmin:** conexão e sync; o card visual já existe.
- **Configurações → Integrações:** abrir já rolada até a seção a partir do card Conectar.
- **Treinos pausados extras:** acesso na Home aos demais pausados (hoje só o mais recente).

## Fora do escopo
- Garmin na Home (57:383) até existir integração — só na `bldr_showcase_screen`.
- Frames ocultos `2:5` e `19:297`.
