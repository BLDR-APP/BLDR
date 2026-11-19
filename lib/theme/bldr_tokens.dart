// BLDR — Design Tokens
// Fonte única de verdade para cores, tipografia, espaçamento e raios.
// Todos os valores correspondem 1:1 aos mockups (logical pixels do Flutter = px do mockup).
//
// NÃO adicionar cores fora deste arquivo. Se precisar de um valor novo, discutir antes.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// CORES
// ─────────────────────────────────────────────────────────────

abstract final class BldrColors {
  // Base
  static const bgBase = Color(0xFF050505);

  // Dourado
  static const goldSolid = Color(0xFFC9A227); // preenchimento de botão primário
  static const goldBright = Color(0xFFE0B830); // texto, ícones, barras, ativo
  static const goldDeep = Color(0xFF8A6D1A); // início do gradiente

  // Dourado translúcido
  static const goldTint =
      Color(0x21E0B830); // rgba(224,184,48,0.13) — fundo de ícone
  static const goldTintStrong =
      Color(0x21C9A227); // rgba(201,162,39,0.13) — card destaque
  static const goldTintChip =
      Color(0x26E0B830); // rgba(224,184,48,0.15) — chip ativo
  static const goldBorder =
      Color(0x47C9A227); // rgba(201,162,39,0.28) — borda destaque
  static const goldBorderChip =
      Color(0x4DE0B830); // rgba(224,184,48,0.30) — borda chip

  // Superfícies (glass)
  static const surface = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const surfaceSubtle = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const surfaceInset = Color(0x08FFFFFF); // rgba(255,255,255,0.03)
  static const border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const borderSubtle = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const navBg = Color(0x8C0A0A0A); // rgba(10,10,10,0.55)
  static const sheetBg = Color(0xEB121212); // rgba(18,18,18,0.92)

  // Texto
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x73FFFFFF); // 0.45
  static const textTertiary = Color(0x59FFFFFF); // 0.35
  static const textMuted = Color(0x40FFFFFF); // 0.25

  // Trilhos e preenchimentos neutros
  static const track = Color(0x14FFFFFF); // trilho de barra de progresso
  static const iconMuted = Color(0x4DFFFFFF); // ícone inativo na nav

  // Semântica — uso restrito
  static const danger = Color(0xFFE06B5A); // SOMENTE ações irreversíveis

  // Gradiente de progresso (barras longas)
  static const progressGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [goldDeep, goldBright],
  );

  // Glow de fundo — obrigatório em toda tela.
  // Sem ele os cards de vidro perdem a refração e viram cinza chapado.
  static const glowPrimary = RadialGradient(
    center: Alignment(0.0, -1.0),
    radius: 0.9,
    colors: [Color(0x33C9A227), Color(0x00C9A227)], // 0.20 → transparente
  );

  static const glowSecondary = RadialGradient(
    center: Alignment(1.0, -0.2),
    radius: 0.7,
    colors: [Color(0x0FC9A227), Color(0x00C9A227)], // 0.06 → transparente
  );
}

// ─────────────────────────────────────────────────────────────
// TIPOGRAFIA
// ─────────────────────────────────────────────────────────────
//
// FONTE: Inter — decidida a partir da auditoria (INVENTARIO.md §3.2).
// O app já usa GoogleFonts.inter em 24 pontos do AppTheme (componentes:
// AppBar, BottomNav, botões, inputs). Montserrat (TextTheme) e JetBrainsMono
// permanecem no AppTheme legado e NÃO são usadas em telas redesenhadas.
//
// Inter está EMPACOTADO localmente (assets/fonts/, seção `fonts:` do pubspec,
// pesos 400/500/600). Por isso `fontFamily: 'Inter'` resolve sem google_fonts:
// sem download em runtime e sem flash na 1ª renderização.
// Não usar GoogleFonts.inter(...) aqui — isso reintroduziria o download.
//
// Peso máximo: w600, e apenas em botões e números de destaque. Nunca w700+.
// O app legado usa w700 e até w900 — telas redesenhadas não seguem isso.

abstract final class BldrText {
  static const String family = 'Inter';

  static const screenTitle = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.2,
  );

  static const sectionTitle = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.2,
  );

  static const cardTitle = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.3,
  );

  static const cardTitleLg = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.3,
  );

  /// KPI grande — peso alvo, calorias, IQD
  static const kpiLg = TextStyle(
    fontFamily: family,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.0,
  );

  /// KPI médio — cards de stat
  static const kpiMd = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.1,
  );

  static const kpiSm = TextStyle(
    fontFamily: family,
    fontSize: 19,
    fontWeight: FontWeight.w500,
    color: BldrColors.textPrimary,
    height: 1.1,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: BldrColors.textPrimary,
    height: 1.4,
  );

  static const description = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: BldrColors.textSecondary,
    height: 1.4,
  );

  static const meta = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: BldrColors.textTertiary,
    height: 1.3,
  );

  static const metaSm = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: BldrColors.textTertiary,
    height: 1.3,
  );

  /// Label maiúsculo — "TREINO DE HOJE", "SQUAD OPERANTE"
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: BldrColors.textSecondary,
    letterSpacing: 0.6,
    height: 1.2,
  );

  static const buttonPrimary = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0A0A0A),
    height: 1.2,
  );

  static const buttonSecondary = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: BldrColors.goldBright,
    height: 1.2,
  );

  /// Unidade colada a um número — sempre menor e em tertiary.
  /// Uso: Text.rich(TextSpan(text: '62', style: kpiLg,
  ///        children: [TextSpan(text: 'kg', style: BldrText.unit)]))
  static const unit = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: BldrColors.textTertiary,
  );
}

// ─────────────────────────────────────────────────────────────
// ESPAÇAMENTO
// ─────────────────────────────────────────────────────────────

abstract final class BldrSpacing {
  static const double pageX = 22; // margem lateral de toda tela
  static const double gapCard = 11; // entre cards do mesmo grupo
  static const double gapSection = 22; // entre seções distintas
  static const double padCard = 19; // interno de card padrão
  static const double padCardLg = 21; // interno de card hero
  static const double padRow = 14; // interno de linha de lista
  // Pílula flutuante: 26px do fundo + ~72px de altura própria (padding
  // vertical 9×2 + item de 46-54px) — 110 dá folga sem colar no último card.
  static const double navClearance = 130;

  static const pageInsets = EdgeInsets.symmetric(horizontal: pageX);
}

// ─────────────────────────────────────────────────────────────
// RAIOS
// ─────────────────────────────────────────────────────────────

abstract final class BldrRadius {
  static const double screen = 32;
  static const double hero = 26;
  static const double cardLg = 22;
  static const double card = 20;
  static const double cardSm = 18;
  static const double input = 15;
  static const double button = 14;
  static const double iconBox = 12;
  static const double pill = 20;
  static const double bar = 4;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

// ─────────────────────────────────────────────────────────────
// BLUR
// ─────────────────────────────────────────────────────────────
//
// ⚠️ CONVERSÃO CRÍTICA: CSS blur(Npx) → Flutter sigma = N / 2.
// Passar o valor do CSS direto no sigma dobra a intensidade e o vidro
// fica leitoso, perdendo o efeito.

abstract final class BldrBlur {
  static const double card = 8; // CSS blur(16px)
  static const double cardLg = 9; // CSS blur(18px)
  static const double nav = 12; // CSS blur(24px)
  static const double sheet = 15; // CSS blur(30px)
  static const double badge = 4; // CSS blur(8px)
}

// ═════════════════════════════════════════════════════════════
// REBRANDING v2 — FIGMA (Bn5NBPkg7Yr1shm5F7vmb0)
// ═════════════════════════════════════════════════════════════
//
// Tokens lidos do mockup da Home (node 57:388). Em telas com mockup no
// Figma, o mockup vence as regras da fase 1 acima (cards sólidos, peso 700,
// cores oficiais do WHOOP, CTA em caixa alta). Os tokens da fase 1 NÃO foram
// alterados: telas ainda não redesenhadas continuam idênticas.
//
// Valores em px do frame de 440 × 956 (1 px = 1 logical pixel).

abstract final class BldrColorsV2 {
  // Base — o SVG de fundo do mockup usa #050505 (igual à fase 1).
  static const bg = BldrColors.bgBase;

  // Dourado
  static const gold = Color(0xFFD4AF37); // bordas, CTA, ícones de stat
  static const goldBright = BldrColors.goldBright; // #E0B830 — barras, inicial
  static const goldFill = Color(0x29D4AF37); // rgba(212,175,55,0.16) — nav
  static const goldBorderSoft =
      Color(0x4DD4AF37); // rgba(212,175,55,0.30) — faixa de nível
  static const avatarBorder = Color(0xFF75601D);
  static const trainBorder = Color(0xFF77601B);

  // Texto
  static const textPrimary = Color(0xFFF7F7F7);
  static const textSecondary = Color(0xFF999999);
  static const textWhite = Color(0xFFFFFFFF);
  static const trainLabel = Color(0xFFBFB19A);
  static const trainMeta = Color(0xFFD8CBAE);

  // Header / nível
  static const avatarBg = Color(0xFF151515);
  static const levelTrack = Color(0xFF444038);
  static const levelFillStart = Color(0xA67A641A); // rgba(122,100,26,0.65)

  // Chips de consistência
  static const chipBg = Color(0xFF211F1B);

  // Grid 2×2
  static const tileBg = Color(0xFF181818);
  static const tileLabel = Color(0xFF858585);
  static const tileValue = Color(0xFFF5F5F5);
  static const tileTrack = Color(0xFF303030);
  static const weekBarIdle = Color(0xFF383838);

  // Pilha de wearable (camadas de trás — genéricas para qualquer wearable)
  static const stackBack = Color(0xFF171613);
  static const stackBackBorder = Color(0x8C49402B); // rgba(73,64,43,0.55)
  static const stackMid = Color(0xFF211F19);
  static const stackMidBorder = Color(0x8C60502A); // rgba(96,80,42,0.55)

  // Card ativo do WHOOP
  static const whoopCardTop = Color(0xFF283339);
  static const whoopCardBottom = Color(0xFF101518);
  static const whoopCardBorder = Color(0xCC39474C); // rgba(57,71,76,0.8)
  static const ringTrack = Color(0xFF343A3B);
  static const ringInner = Color(0xFF101518);
  static const ringLabel = Color(0xFFAFAAA0);
  static const whoopToday = Color(0xFFA9A49B);

  // Navbar
  static const navIcon = Color(0xFF939393);

  // Gradientes
  static const levelFillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [levelFillStart, goldBright],
  );

  static const whoopCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [whoopCardTop, whoopCardBottom],
  );

  // Glows elípticos (3 paradas) — desenhados por `BldrEllipseGlow`.
  static const glowColors = [
    Color(0x33C9A227), // 0.20
    Color(0x16C9A227), // 0.085
    Color(0x00C9A227),
  ];
  static const glowStops = [0.0, 0.46, 1.0];
  static const glowSecondaryColors = [
    Color(0x0FC9A227), // 0.0588
    Color(0x06C9A227), // 0.024
    Color(0x00C9A227),
  ];
  static const glowSecondaryStops = [0.0, 0.48, 1.0];
}

/// Cores oficiais do WHOOP (Brand & Design Guidelines). Antes eram `const`
/// privados em `bldr_whoop_card.dart`; os valores não mudaram.
abstract final class BldrWhoopColors {
  static const recoveryHigh = Color(0xFF16EC06); // 100–67%
  static const recoveryMed = Color(0xFFFFDE00); // 66–34%
  static const recoveryLow = Color(0xFFFF0026); // 33–0%
  static const recoveryEmpty = Color(0xFF67AEE6); // recovery sem valor
  static const strain = Color(0xFF0093E7);
  static const sleep = Color(0xFF7BA1BB);
  static const track = Color(0x12FFFFFF); // trilho do estado de skeleton
}

/// Tipografia v2. `height: 1.21` reproduz o "line-height: normal" do Inter
/// no Figma.
abstract final class BldrTextV2 {
  static const String family = BldrText.family;
  static const double _h = 1.21;

  /// Escala tipográfica fixa do rebranding v2 (aprovada). Cada tamanho do
  /// mockup vai para o degrau mais próximo (empate → degrau de cima), com
  /// mínimo de 11. Pesos, cores e espaçamento entre letras seguem o mockup.
  /// Use sempre [scale]; nunca tamanhos soltos em telas novas.
  static const double s11 = 11;
  static const double s12 = 12;
  static const double s13 = 13;
  static const double s15 = 15;
  static const double s17 = 17;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;

  static TextStyle scale(double step, FontWeight weight, Color color,
          {double? letterSpacing}) =>
      TextStyle(
        fontFamily: family,
        fontSize: step,
        fontWeight: weight,
        color: color,
        height: _h,
        letterSpacing: letterSpacing,
      );

  static const _base = TextStyle(fontFamily: family, height: _h);

  // Header
  static final greeting = _base.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: BldrColorsV2.textSecondary);
  static final title = _base.copyWith(
      fontSize: 31,
      fontWeight: FontWeight.w700,
      color: BldrColorsV2.textPrimary);
  static final avatarInitial = _base.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: BldrColorsV2.goldBright);

  // Nível / XP
  static final level = _base.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: BldrColorsV2.textPrimary);
  static final xp = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: BldrColorsV2.textSecondary);

  // Chips
  static final statValue = _base.copyWith(
      fontSize: 19, fontWeight: FontWeight.w400, color: BldrColorsV2.textWhite);
  static final statLabel = _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w300, color: BldrColorsV2.textWhite);

  // WHOOP
  static final whoopToday = _base.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: BldrColorsV2.whoopToday);
  static final ringValue =
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final ringLabel = _base.copyWith(
      fontSize: 9, fontWeight: FontWeight.w400, color: BldrColorsV2.ringLabel);

  // Treino de hoje
  static final trainLabel = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: BldrColorsV2.trainLabel);
  static final trainTitle = _base.copyWith(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      color: BldrColorsV2.textPrimary);
  static final trainMuscles = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: BldrColorsV2.textSecondary);
  static final trainMeta = _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w500, color: BldrColorsV2.trainMeta);
  static final cta = _base.copyWith(
      fontSize: 13, fontWeight: FontWeight.w700, color: BldrColorsV2.gold);

  // Grid 2×2
  static final tileLabel = _base.copyWith(
      fontSize: 10, fontWeight: FontWeight.w400, color: BldrColorsV2.tileLabel);
  static final tileValue = _base.copyWith(
      fontSize: 23, fontWeight: FontWeight.w600, color: BldrColorsV2.tileValue);
  static final macroValue = _base.copyWith(
      fontSize: 10, fontWeight: FontWeight.w400, color: BldrColorsV2.tileValue);
  static final weekDay = _base.copyWith(
      fontSize: 8, fontWeight: FontWeight.w400, color: BldrColorsV2.tileLabel);

  // Cards de estado do wearable (57:382 / 57:381)
  static final wearableLabel = _base.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: BldrColorsV2.goldBright);
  static final wearableTitle = _base.copyWith(
      fontSize: 19, fontWeight: FontWeight.w600, color: BldrColorsV2.tileValue);
  static final wearableBody11 = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: BldrWearableColorsV2.connectBody);
  static final wearableBody12 = _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: BldrWearableColorsV2.unavailableBody);
  static final wearableCta = _base.copyWith(
      fontSize: 12, fontWeight: FontWeight.w600, color: BldrColorsV2.gold);
  static final wearableLink = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: BldrColorsV2.goldBright);

  // Treino concluído (57:379) — cores de BldrTrainColorsV2
  static final doneStat =
      _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600);

  // Garmin (57:383) — cores de BldrGarminColors
  static final garminValue =
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
  static final garminLabel = _base.copyWith(
      fontSize: 9, fontWeight: FontWeight.w400, color: BldrGarminColors.label);
  static final garminFooter = _base.copyWith(
      fontSize: 10, fontWeight: FontWeight.w400, color: BldrGarminColors.label);

  // Havok (57:390 / 57:389)
  static final havokBannerLabel = _base.copyWith(
      fontSize: 8.719,
      fontWeight: FontWeight.w600,
      color: BldrColorsV2.goldBright);
  static final havokBannerText = _base.copyWith(
      fontSize: 11.334,
      fontWeight: FontWeight.w500,
      color: BldrColorsV2.textWhite);
  static final havokBannerChevron = _base.copyWith(
      fontSize: 20.925,
      fontWeight: FontWeight.w700,
      color: BldrColorsV2.goldBright);
  static final havokLabel = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: BldrColorsV2.goldBright);
  static final havokClose = _base.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w500,
      color: BldrHavokColorsV2.muted);
  static final havokTitle = _base.copyWith(
      fontSize: 17, fontWeight: FontWeight.w600, color: BldrColorsV2.textWhite);
  static final havokBody = _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: BldrHavokColorsV2.muted);
  static final havokCta = _base.copyWith(
      fontSize: 12, fontWeight: FontWeight.w700, color: BldrColorsV2.gold);
}

abstract final class BldrSpacingV2 {
  /// Largura de referência do frame. Em 440 px tudo fica idêntico ao mockup;
  /// abaixo disso as margens escalam proporcionalmente (ver [pageX]).
  static const double frameWidth = 440;
  static const double pageXRef = 27;

  /// Margem lateral proporcional à largura (27 em 440), mínimo 16.
  static double pageX(double screenWidth) =>
      (pageXRef * screenWidth / frameWidth).clamp(16.0, pageXRef);

  // Respiros verticais entre seções da Home
  static const double headerToLevel = 12;
  static const double levelToChips = 31;
  static const double chipsToWearable = 18;
  static const double wearableToTrain = 20;
  static const double trainToGrid = 18;

  // Grid 2×2
  static const double gridGapX = 10;
  static const double gridGapY = 8;
  static const double tileHeight = 96;
  static const double tilePad = 13;

  // Chips de consistência
  static const double chipWidth = 81;
  static const double chipHeight = 78;
  static const double chipGap = 13;

  // Treino de hoje
  static const double trainPad = 18;

  // Navbar
  static const double navHeight = 42;
  static const double navBottom = 22;
}

abstract final class BldrRadiusV2 {
  static const double chip = 18;
  static const double wearableCard = 18;
  static const double train = 23;
  static const double cta = 15;
  static const double tile = 17;
  static const double levelStrip = 27;
  static const double navPill = 60;
  static const double navHavok = 15;
  static const double tileBar = 2;
  static const double weekBar = 5;
  static const double levelBar = 4;
}

// ─────────────────────────────────────────────────────────────
// v2 — PILHA DE WEARABLE: 4ª camada (proposta aprovada; não existe no Figma)
// ─────────────────────────────────────────────────────────────

abstract final class BldrStackV2 {
  /// Altura total fixa da pilha — não muda com o número de camadas.
  static const double height = 188;
  static const double activeHeight = 173;

  /// Geometria por camada (0 = frente). Com 3 camadas: mockup (15/7/0,
  /// recuos 0/3/7). Com 4: 15/10/5/0, recuos 0/3/6/9.
  static const tops3 = [15.0, 7.0, 0.0];
  static const insets3 = [0.0, 3.0, 7.0];
  static const tops4 = [15.0, 10.0, 5.0, 0.0];
  static const insets4 = [0.0, 3.0, 6.0, 9.0];
  // Distância da base de cada camada até a base da pilha.
  static const bottoms3 = [0.0, 7.0, 12.0];
  static const bottoms4 = [0.0, 4.0, 8.0, 12.0];

  static const layer4 = Color(0xFF100F0D);
  static const layer4Border = Color(0x8C373021); // rgba(55,48,33,0.55)

  static const Duration animation = Duration(milliseconds: 320);

  // Indicador de posição (proposta aprovada)
  static const dotActive = BldrColorsV2.gold;
  static const dotIdle = BldrColorsV2.levelTrack; // #444038
}

// ─────────────────────────────────────────────────────────────
// v2 — CARDS DE ESTADO DO WEARABLE (Figma 57:382 / 57:381)
// ─────────────────────────────────────────────────────────────

abstract final class BldrWearableColorsV2 {
  static const connectSurface = Color(0xFF17191A);
  static const connectBody = Color(0xFFA0A0A0);
  static const unavailableTitle = Color(0xFFF4F4F4);
  static const unavailableBody = Color(0xFF969696);
  static const double connectCtaRadius = 12;
}

/// Cores do card Garmin (Figma 57:383) — exatamente as do mockup, por
/// exigência do manual de marca da Garmin. Não substituir por tokens v2.
abstract final class BldrGarminColors {
  static const surface = Color(0xFF111315);
  static const border = Color(0xCC454A4D); // rgba(69,74,77,0.8)
  static const metricBox = Color(0xFF222629);
  static const bodyBattery = Color(0xFF6DCFF6);
  static const value = Color(0xFFFFFFFF);
  static const label = Color(0xFFB7BFC3);
  static const today = Color(0xFFA9A49B);
  static const double metricRadius = 12;
}

// ─────────────────────────────────────────────────────────────
// v2 — HAVOK (Figma 57:390 banner / 57:389 card expandido)
// ─────────────────────────────────────────────────────────────

abstract final class BldrHavokColorsV2 {
  static const surface = Color(0xFF050505);
  static const bannerBorder = BldrColorsV2.gold;
  static const expandedBorder = Color(0xFF806826);
  static const muted = Color(0xFFBDBDBD);
  static const label = BldrColorsV2.goldBright;
}

abstract final class BldrHavokV2 {
  static const double bannerWidth = 279;
  static const double bannerHeight = 45.338;
  static const double bannerRadius = 22.669;
  static const double bannerBorderWidth = 0.872;
  static const double expandedWidth = 370;
  static const double expandedHeight = 205;
  static const double expandedRadius = 24;
  static const Duration transition = Duration(milliseconds: 300);
}

// ─────────────────────────────────────────────────────────────
// v2 — TREINO DE HOJE: estados (Figma 57:386 / 57:385 / 57:380 / 57:379)
// ─────────────────────────────────────────────────────────────

abstract final class BldrTrainColorsV2 {
  /// Check duplo do estado concluído — verde do mockup (prevalece).
  static const success = Color(0xFF16EC06);
  // CTA neutro (dia de descanso)
  static const ctaNeutralBg = Color(0xFF1B1B1B);
  static const ctaNeutralBorder = Color(0xFF5C5C5C);
  static const ctaNeutralText = Color(0xFFE0E0E0);
  // Métricas do concluído
  static const doneLabel = Color(0xFF5C5C5C);
  static const doneValue = BldrColorsV2.tileValue; // #F5F5F5
}

// ─────────────────────────────────────────────────────────────
// v2 — TREINOS (Figma guqp4TpJiiCKjhSgzqxSjg — 179:981 / 179:1015 / 179:1117)
// ─────────────────────────────────────────────────────────────

abstract final class BldrWorkoutColorsV2 {
  static const text = Color(0xFFF0F0F0);
  static const muted = Color(0xFF787878);
  static const gold = BldrColorsV2.goldBright; // #E0B830

  // CTA com borda (＋ … ›) e botão compacto
  static const ctaBg = Color(0xFF0F0E0A);
  static const ctaBorder = Color(0x7AD4AF37); // .48

  // Campo de nome
  static const inputBg = Color(0xD10A0A0A); // rgba(10,10,10,.82)
  static const inputBorder = Color(0x4DD4AF37); // .30

  // Seletor de tipo
  static const typeBoxBg = Color(0x800A0A0A); // .50
  static const typeBoxBorder = Color(0x24D4AF37); // .14
  static const typeChipBg = Color(0x9E0A0A0A); // .62
  static const typeChipSelBg = Color(0xFF0E0D09);
  static const typeChipSelBorder = Color(0x9ED4AF37); // .62

  // HUD
  static const hudBg = Color(0xC70A0A0A); // .78
  static const hudBorder = Color(0x2ED4AF37); // .18

  // Card de exercício configurado
  static const cardBg = Color(0xC70A0A0A); // .78
  static const cardExpandedBg = Color(0xCC0A0A0A); // .80
  static const cardBorder = Color(0x29D4AF37); // .16
  static const cardExpandedBorder = Color(0x5CD4AF37); // .36
  static const thumbBg = Color(0xFF0E0E0E);
  static const thumbBorder = Color(0x2ED4AF37); // .18
  static const valueBg = Color(0xB80A0A0A); // .72
  static const valueBorder = Color(0x1FD4AF37); // .12
  static const setBoxBg = Color(0xB30A0A0A); // .70
  static const setBoxBorder = Color(0x1AD4AF37); // .10

  // Sheet "Adicionar exercícios"
  static const sheetBg = Color(0xFC080808); // rgba(8,8,8,.99)
  static const sheetBorder = Color(0x75D4AF37); // .46
  static const grabber = Color(0xFF575757);
  static const searchBg = Color(0xD1080808); // .82
  static const searchBorder = Color(0x24D4AF37); // .14
  static const filterSelBg = Color(0xE6080808); // .90
  static const filterSelBorder = Color(0x80D4AF37); // .50
  static const filterBg = Color(0x8C080808); // .55
  static const filterBorder = Color(0x1AD4AF37); // .10
  static const itemBg = Color(0xC7080808); // .78
  static const itemSelBorder = Color(0x61D4AF37); // .38
  static const itemBorder = Color(0x1AD4AF37); // .10
  static const itemThumbBg = Color(0xE6080808); // .90
  static const itemThumbBorder = Color(0x1FD4AF37); // .12
  static const equipBg = Color(0x8C080808); // .55
  static const equipBorder = Color(0x14D4AF37); // .08
  static const pickSelBg = Color(0xFA080808); // .98
  static const pickSelBorder = Color(0xADD4AF37); // .68
  static const pickBg = Color(0xB8080808); // .72
  static const pickBorder = Color(0x2ED4AF37); // .18

  // Hub (249:18901 / 179:2)
  static const goldBrand = Color(0xFFD4AF37);
  static const secondary = Color(0xFF6F6F6F);
  static const tabIdle = Color(0xFF949494);
  static const todayBorder = goldBrand;
  static const pillBorder = Color(0x7AD4AF37); // .48
  static const weekCircle = Color(0xFFD9D9D9);
  static const weekIcon = Color(0xFF1A1A1A);
  static const listCardBg = Color(0x4D353535); // rgba(53,53,53,.3)
  static const listCardBorder = Color(0xCFD4AF37); // .81
  static const exploreBg = Color(0xFF353535);
  static const divider = Color(0x66D4AF37);

  // Hub revisado (305:1656 / 310:195)
  static const libraryMenuBg = Color(0xFF060606);
  static const libraryMenuBorder = Color(0xFFC9A227);
  static const libraryMenuDesc = Color(0xFF8C8C8C);
  static const myCardMapBg = Color(0xF2303336); // rgba(48,51,54,.95)
  static const myCardMuted = Color(0xFF999CA1);
  static const myCardDivider = Color(0xF2474A4D); // rgba(71,74,77,.95)
  static const pageDotIdle = secondary;

  // Editor (179:1590)
  static const editorIdentityBorder = Color(0x3DD4AF37); // .24
  static const editorExpandedBorder = Color(0x6BD4AF37); // .42
  static const editorChipBg = Color(0xF2121212); // rgba(18,18,18,.95)
}

/// Textos de Treinos v2 na escala do rebranding (`BldrTextV2.scale`).
/// Conversão aprovada (mockup → degrau) registrada no TREINOS_V2.md.
abstract final class BldrWorkoutTextV2 {
  static const _b = FontWeight.w700;
  static const _sb = FontWeight.w600;
  static const _m = FontWeight.w500;
  static const _r = FontWeight.w400;
  static const _t = BldrWorkoutColorsV2.text;
  static const _mu = BldrWorkoutColorsV2.muted;
  static const _g = BldrWorkoutColorsV2.gold;
  static TextStyle _s(double step, FontWeight w, Color c, {double? ls}) =>
      BldrTextV2.scale(step, w, c, letterSpacing: ls);

  // ── Criar treino (179:981 / 179:1015 / 179:1117) ──
  static final back = _s(BldrTextV2.s28, _r, _t); // 30
  static final eyebrow = _s(BldrTextV2.s11, _b, _g); // 10
  static final eyebrowSm = _s(BldrTextV2.s11, _b, _g); // 9
  static final title = _s(BldrTextV2.s24, _b, _t); // 24
  static final subtitle = _s(BldrTextV2.s12, _m, _mu); // 12
  static final sectionLabel = _s(BldrTextV2.s11, _b, _mu); // 9
  static final inputValue = _s(BldrTextV2.s24, _sb, _t); // 22
  static final typeChip = _s(BldrTextV2.s11, _b, _mu); // 9
  static final soon = _s(BldrTextV2.s11, _b, _mu); // 6
  static final cta = _s(BldrTextV2.s11, _b, _g); // 11
  static final ctaSm = _s(BldrTextV2.s11, _sb, _g, ls: 0.8); // 9
  static final ctaArrow = _s(BldrTextV2.s20, _r, _g); // 21
  static final hint = _s(BldrTextV2.s11, _m, _mu); // 10
  static final hintSm = _s(BldrTextV2.s11, _m, _mu); // 8
  static final count = _s(BldrTextV2.s11, _b, _g); // 8
  static final compactCta = _s(BldrTextV2.s11, _b, _g); // 8
  static final hudValue = _s(BldrTextV2.s15, _b, _g); // 14
  static final hudLabel = _s(BldrTextV2.s11, _b, _mu); // 7
  static final exName = _s(BldrTextV2.s13, _sb, _t); // 11 → 13 (hierarquia)
  static final exMuscles = _s(BldrTextV2.s11, _m, _mu); // 8
  static final valueBox = _s(BldrTextV2.s13, _b, _t); // 8 → 13 (hierarquia)
  static final valueLabel = _s(BldrTextV2.s11, _b, _mu); // 6
  static final remove = _s(BldrTextV2.s15, _r, _mu); // 15
  static final personalize = _s(BldrTextV2.s11, _b, _g); // 7
  static final advancedHint = _s(BldrTextV2.s11, _m, _mu); // 7
  static final setIndex = _s(BldrTextV2.s11, _b, _g); // 8
  static final setValue = _s(BldrTextV2.s12, _sb, _t); // 8 → 12 (hierarquia)
  static final more = _s(BldrTextV2.s11, _b, _mu); // 11
  static final addSet = _s(BldrTextV2.s11, _b, _mu); // 7
  static final sheetTitle = _s(BldrTextV2.s24, _b, _t); // 22
  static final search = _s(BldrTextV2.s11, _m, _mu); // 10
  static final filter = _s(BldrTextV2.s11, _b, _mu); // 7
  static final listLabel = _s(BldrTextV2.s11, _b, _mu); // 8
  static final itemName = _s(BldrTextV2.s13, _sb, _t); // 10 → 13 (hierarquia)
  static final equip = _s(BldrTextV2.s11, _b, _mu); // 6
  static final sheetCta = _s(BldrTextV2.s11, _b, _g); // 10

  // ── Hub (249:18901 / 179:2) ──
  static final hubTabActive = _s(BldrTextV2.s17, _sb, _g); // 16
  static final hubTab =
      _s(BldrTextV2.s17, _sb, BldrWorkoutColorsV2.tabIdle); // 16
  static final todayLabel =
      _s(BldrTextV2.s12, _r, BldrWorkoutColorsV2.goldBrand); // 12
  static final todayName = _s(BldrTextV2.s12, _b, Colors.white); // 12
  static final todayHint =
      _s(BldrTextV2.s12, _r, BldrWorkoutColorsV2.secondary); // 12
  static final pillLabel = _s(BldrTextV2.s11, _b, _g); // 7 / 5,4
  static final metaWhite = _s(BldrTextV2.s11, _r, Colors.white); // 7 / 8
  static final hubSection = _s(BldrTextV2.s11, _r, Colors.white); // 10
  static final weekDay = _s(BldrTextV2.s12, _r, Colors.white); // 12
  static final weekValue = _s(BldrTextV2.s15, _r, Colors.white); // 14
  static final weekLabel = _s(BldrTextV2.s11, _r, Colors.white); // 9
  static final cardName = _s(BldrTextV2.s15, _b, Colors.white); // 14
  static final cardMuscles =
      _s(BldrTextV2.s11, _m, BldrWorkoutColorsV2.secondary); // 9
  static final cardStats = _s(BldrTextV2.s11, _m, _t); // 8
  static final countGold =
      _s(BldrTextV2.s11, _r, BldrWorkoutColorsV2.goldBrand); // 6
  static final emptyTitle = _s(BldrTextV2.s11, _r, Colors.white); // 8 (Inter)
  static final emptySub =
      _s(BldrTextV2.s11, _r, BldrWorkoutColorsV2.secondary); // 8
  static final exploreTitle = _s(BldrTextV2.s11, _r, Colors.white); // 6,6
  static final exploreSub =
      _s(BldrTextV2.s11, _r, BldrWorkoutColorsV2.secondary); // 4,1

  // ── Hub revisado (305:1656 / 310:195) ──
  static final myHeader = _s(BldrTextV2.s11, _r, _t); // 10
  static final myCount =
      _s(BldrTextV2.s11, _sb, BldrWorkoutColorsV2.goldBrand); // 9
  static final myCardName = _s(BldrTextV2.s15, _b, _t); // 14
  static final myCardGroups =
      _s(BldrTextV2.s11, _m, BldrWorkoutColorsV2.myCardMuted); // 9
  static final myCardStats =
      _s(BldrTextV2.s11, _m, BldrWorkoutColorsV2.myCardMuted); // 9
  static final myCardMinutes =
      _s(BldrTextV2.s11, _sb, BldrWorkoutColorsV2.goldBrand); // 9
  static final menuTitle = _s(BldrTextV2.s11, _r, Colors.white); // 10,8
  static final menuDesc =
      _s(BldrTextV2.s11, _r, BldrWorkoutColorsV2.libraryMenuDesc); // 8
  static final tip = _s(BldrTextV2.s12, _m, Colors.white);

  // ── Editor (179:1590) ──
  static final edName = _s(BldrTextV2.s24, _b, _t); // 25
  static final edLabel = _s(BldrTextV2.s11, _b, _mu); // 9 / 8
  static final edGroups = _s(BldrTextV2.s11, _m, _mu); // 11
  static final edHudValue = _s(BldrTextV2.s17, _b, _t); // 17
  static final edHudAccent = _s(BldrTextV2.s17, _b, _g); // 17
  static final edOrder = _s(BldrTextV2.s11, _b, _g); // 10
  static final edExName = _s(BldrTextV2.s15, _sb, _t); // 15
  static final edMuscles = _s(BldrTextV2.s11, _m, _mu); // 10
  static final edChip = _s(BldrTextV2.s11, _sb, _t); // 9
  static final edChipAccent = _s(BldrTextV2.s11, _sb, _g); // 9
  static final edMenu = _s(BldrTextV2.s13, _b, _mu); // 13
  static final edPersonalize = _s(BldrTextV2.s11, _b, _mu); // 7
  static final edDefault = _s(BldrTextV2.s11, _sb, _t); // 11
  static final edDefaultAccent = _s(BldrTextV2.s11, _b, _g); // 11
  static final edSetIndex = _s(BldrTextV2.s11, _b, _mu); // 11
  static final edSetValue = _s(BldrTextV2.s11, _sb, _t); // 11
  static final edAddSet = _s(BldrTextV2.s11, _b, _g); // 9
  static final edAddCount = _s(BldrTextV2.s11, _sb, _mu); // 9
}

// ─────────────────────────────────────────────────────────────
// SHEET V2 + TREINO EM ANDAMENTO (179:1319 / 179:1401 / 179:1496)
// ─────────────────────────────────────────────────────────────

abstract final class BldrSheetV2Colors {
  static const bg = Color(0xF2000000); // rgba(0,0,0,.95)
  static const border = Color(0xFFD4AF37);
  static const grabber = Color(0xFFCCCCCC);
  static const scrim = Color(0xB3000000);
  static const button = Color(0xFF0A0A0A);
  static const buttonBorder = Color(0xFF3A3A3A);
  static const indicator = Color(0xA6D4AF37); // .65
  static const text = Color(0xFFF5F5F5);
  static const unit = Color(0xFF787878);
}

abstract final class BldrSheetV2Text {
  static final title =
      BldrTextV2.scale(BldrTextV2.s17, FontWeight.w700, BldrSheetV2Colors.text);
  static final value = // 48 → 32 (degrau máximo)
      BldrTextV2.scale(BldrTextV2.s32, FontWeight.w700, BldrSheetV2Colors.text);
  static final unit =
      BldrTextV2.scale(BldrTextV2.s12, FontWeight.w500, BldrSheetV2Colors.unit);
  static final option =
      BldrTextV2.scale(BldrTextV2.s15, FontWeight.w600, BldrSheetV2Colors.text);
  static final label =
      BldrTextV2.scale(BldrTextV2.s11, FontWeight.w600, BldrSheetV2Colors.unit);
  static final body =
      BldrTextV2.scale(BldrTextV2.s13, FontWeight.w400, BldrSheetV2Colors.text);
}

// Confirmação v2 (320:214)
abstract final class BldrConfirmV2Colors {
  static const bg = Color(0xFF050505);
  static const scrim = Color(0xA8000000); // .66
  static const cancelBg = Color(0xFF404247);
  static const cancelText = Color(0xFFF0F0F2);
  static const destructive = Color(0xFFFF0000);
  static const message = Color(0xFFA6A8AD);
}

abstract final class BldrConfirmV2Text {
  static final title = BldrTextV2.scale(
      BldrTextV2.s20, FontWeight.w600, BldrConfirmV2Colors.cancelText); // 20
  static final message = BldrTextV2.scale(
      BldrTextV2.s12, FontWeight.w500, BldrConfirmV2Colors.message); // 12
  static final button = BldrTextV2.scale(
      BldrTextV2.s13, FontWeight.w600, BldrConfirmV2Colors.cancelText); // 13
  static final primary = BldrTextV2.scale(
      BldrTextV2.s13, FontWeight.w700, BldrSheetV2Colors.border);
}

abstract final class BldrActiveColorsV2 {
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF7D7D7D);
  static const gold = Color(0xFFE0B830);
  static const goldBrand = Color(0xFFD4AF37);
  static const hudBg = Color(0xD10B0B0B); // .82
  static const hudAccentBorder = Color(0x73D4AF37); // .45
  static const closeBg = Color(0xFF111111);
  static const closeBorder = Color(0xFF343434);
  static const badgeBorder = Color(0xA6D4AF37); // .65
  static const mediaBg = Color(0xFF0B0B0B);
  static const mediaInner = Color(0xFF121212);
  static const mediaInnerBorder = Color(0xFF2A2A2A);
  static const cueBg = Color(0xFF080808);
  static const cardBg = Color(0xF00B0B0B); // .94
  static const cardBorder = Color(0xFF303030);
  static const inputBorder = Color(0xFF3A3A3A);
  static const pauseBorder = Color(0x8CD4AF37); // .55
}

abstract final class BldrActiveTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _b = FontWeight.w700;
  static const _sb = FontWeight.w600;
  static const _m = FontWeight.w500;
  static const _r = FontWeight.w400;

  static final status = _s(BldrTextV2.s11, _sb, BldrActiveColorsV2.gold); // 10
  static final name = _s(BldrTextV2.s24, _b, BldrActiveColorsV2.text); // 22
  static final label = _s(BldrTextV2.s11, _sb, BldrActiveColorsV2.muted); // 8/9
  static final timer = _s(BldrTextV2.s20, _b, BldrActiveColorsV2.text); // 20
  static final hudValue = _s(BldrTextV2.s15, _b, BldrActiveColorsV2.text); // 15
  static final hudAccent =
      _s(BldrTextV2.s15, _b, BldrActiveColorsV2.gold); // 15
  static final hudSuffix =
      _s(BldrTextV2.s11, _m, BldrActiveColorsV2.muted); // 8
  static final eyebrow = _s(BldrTextV2.s11, _sb, BldrActiveColorsV2.gold); // 9
  static final exName = _s(BldrTextV2.s24, _b, BldrActiveColorsV2.text); // 25
  static final muscles = _s(BldrTextV2.s11, _r, BldrActiveColorsV2.muted); // 10
  static final badge = _s(BldrTextV2.s11, _sb, BldrActiveColorsV2.gold); // 9
  static final cueTarget =
      _s(BldrTextV2.s11, _sb, BldrActiveColorsV2.gold); // 9
  static final nextSet = _s(BldrTextV2.s20, _b, BldrActiveColorsV2.text); // 20
  static final inputValue =
      _s(BldrTextV2.s32, _b, BldrActiveColorsV2.text); // 30
  static final inputUnit =
      _s(BldrTextV2.s11, _m, BldrActiveColorsV2.muted); // 10
  static final restValue =
      _s(BldrTextV2.s17, _b, BldrActiveColorsV2.text); // 16
  static final restAdd = _s(BldrTextV2.s11, _b, BldrActiveColorsV2.gold);
  static final cta = _s(BldrTextV2.s15, _b, BldrActiveColorsV2.goldBrand); // 14
  static final nextName =
      _s(BldrTextV2.s12, _sb, BldrActiveColorsV2.text); // 12
}

// Resumo (211:5)
abstract final class BldrSummaryColorsV2 {
  static const badgeBg = Color(0xFF211B08);
  static const badgeBorder = Color(0xE6E0B830); // .9
  static const cardBorder = Color(0xE6303030); // .9
  static const divider = Color(0xBF303030); // .75
  static const prBg = Color(0xFF111111);
  static const doneBg = Color(0x66D4AF37); // .4
  static const doneText = Color(0xFFF0F0F0);
}

abstract final class BldrSummaryTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _t = BldrActiveColorsV2.text;
  static const _mu = BldrActiveColorsV2.muted;
  static const _g = BldrActiveColorsV2.gold;

  static final badge = _s(BldrTextV2.s11, FontWeight.w700, _g); // 9
  static final name = _s(BldrTextV2.s32, FontWeight.w700, _t); // 30
  static final meta = _s(BldrTextV2.s11, FontWeight.w600, _mu); // 10
  static final message = _s(BldrTextV2.s12, FontWeight.w400, _t); // 12
  static final section = _s(BldrTextV2.s11, FontWeight.w600, _mu); // 9
  static final metricLabel = _s(BldrTextV2.s11, FontWeight.w600, _mu); // 8
  static final metricValue = _s(BldrTextV2.s17, FontWeight.w700, _t); // 18
  static final metricAccent = _s(BldrTextV2.s17, FontWeight.w700, _g); // 18
  static final metricSuffix = _s(BldrTextV2.s11, FontWeight.w500, _mu); // 8
  static final hlLabel = _s(BldrTextV2.s11, FontWeight.w700, _g); // 8
  static final prValue = _s(BldrTextV2.s15, FontWeight.w700, _t); // 14
  static final hlHint = _s(BldrTextV2.s11, FontWeight.w400, _mu); // 8/9
  static final xpValue = _s(BldrTextV2.s24, FontWeight.w700, _t); // 23
  static final prLine = _s(BldrTextV2.s13, FontWeight.w600, _t);
  static final emphasis = _s(BldrTextV2.s15, FontWeight.w700, _t); // 15
  static final phrase = _s(BldrTextV2.s11, FontWeight.w400, _mu); // 11
  static final muscle = _s(BldrTextV2.s11, FontWeight.w600, _mu); // 8
  static final levelHigh = _s(BldrTextV2.s11, FontWeight.w700, _g); // 8
  static final levelModerate = _s(BldrTextV2.s11, FontWeight.w700, _t); // 8
  static final share =
      _s(BldrTextV2.s11, FontWeight.w700, BldrActiveColorsV2.goldBrand); // 11
  static final done =
      _s(BldrTextV2.s11, FontWeight.w700, BldrSummaryColorsV2.doneText); // 10
}

// Compartilhar v2 (241:12891 / 241:12890)
abstract final class BldrShareColorsV2 {
  static const gold = Color(0xFFD4AF37);
  static const goldBright = Color(0xFFE0B830);
  static const text = Color(0xFFF5F5F5);
  static const label = Color(0xFF7A7A7A);
  static const muted = Color(0xFF7D7D7D);
  static const divider = Color(0xFF2E2E2E);
  static const panelBg = Color(0xFF0B0B0B);
  static const panelBorder = Color(0xE6303030); // .9
  static const canvasBg = Color(0xE6111111); // #111 · .9
}

abstract final class BldrShareTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static final back =
      _s(BldrTextV2.s28, FontWeight.w400, BldrShareColorsV2.text); // 30
  static final title =
      _s(BldrTextV2.s15, FontWeight.w700, BldrShareColorsV2.text); // 15
  static final subtitle =
      _s(BldrTextV2.s11, FontWeight.w400, BldrShareColorsV2.muted); // 9
  static final tab =
      _s(BldrTextV2.s11, FontWeight.w700, BldrShareColorsV2.muted); // 9
  static final tabActive =
      _s(BldrTextV2.s11, FontWeight.w700, BldrShareColorsV2.gold); // 9
  static final hint =
      _s(BldrTextV2.s11, FontWeight.w600, BldrShareColorsV2.muted); // 7/8
  static final infoTitle =
      _s(BldrTextV2.s11, FontWeight.w700, BldrShareColorsV2.text); // 11
  static final infoBody =
      _s(BldrTextV2.s11, FontWeight.w400, BldrShareColorsV2.muted); // 9
  static final cta =
      _s(BldrTextV2.s11, FontWeight.w700, BldrShareColorsV2.gold); // 11
  static final note =
      _s(BldrTextV2.s11, FontWeight.w400, BldrShareColorsV2.muted); // 8
  static final publish =
      _s(BldrTextV2.s12, FontWeight.w600, BldrShareColorsV2.goldBright);
}

// Detalhes do treino / exercício (316:113 · 320:113 · 322:113)
abstract final class BldrDetailsColorsV2 {
  static const headerButton = Color(0xFF212429);
  static const text = Color(0xFFF5F5F7);
  static const value = Color(0xFFF0F0F2);
  static const muted = Color(0xFF9CA1A8);
  static const label = Color(0xFFA6A8AD);
  static const exMuted = Color(0xFFA3A8B0);
  static const goldLabel = Color(0xFFD6B038);
  static const gold = Color(0xFFD4AF37);
  static const panelBg = Color(0x42353535); // rgba(53,53,53,.26)
  static const divider = Color(0x8C57595E); // rgba(87,89,94,.55)
  static const gifBg = Color(0xFF33363B);
  static const gifBorder = Color(0x9966696E); // .6
  static const separator = Color(0xB354575C); // rgba(84,87,92,.7)
  static const tipBg = Color(0xA6333336); // rgba(51,51,54,.65)
  static const destructive = Color(0xFFFF0000);
  static const menuBg = Color(0xFF050505);
}

abstract final class BldrDetailsTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _b = FontWeight.w700, _sb = FontWeight.w600, _m = FontWeight.w500;
  static final eyebrow = _s(BldrTextV2.s11, _sb, BldrDetailsColorsV2.muted); // 8
  static final name = _s(BldrTextV2.s20, _b, BldrDetailsColorsV2.text); // 19
  static final metricLabel = _s(BldrTextV2.s11, _sb, BldrDetailsColorsV2.label); // 9
  static final metricValue = _s(BldrTextV2.s15, _sb, BldrDetailsColorsV2.value); // 15
  static final metricCaption = _s(BldrTextV2.s11, _sb, BldrDetailsColorsV2.goldLabel); // 8
  static final section = _s(BldrTextV2.s15, _b, BldrDetailsColorsV2.text); // 14
  static final count = _s(BldrTextV2.s11, _m, BldrDetailsColorsV2.muted); // 10
  static final exName = _s(BldrTextV2.s11, _sb, BldrDetailsColorsV2.text); // 11
  static final exSub = _s(BldrTextV2.s11, _m, BldrDetailsColorsV2.muted); // 10
  static final cta = _s(BldrTextV2.s13, _b, BldrDetailsColorsV2.gold); // 13
  static final note = _s(BldrTextV2.s11, _m, BldrDetailsColorsV2.muted); // 10
  static final menuItem = _s(BldrTextV2.s13, _sb, BldrDetailsColorsV2.value);
  static final exTitle = _s(BldrTextV2.s12, _sb, BldrDetailsColorsV2.exMuted); // 12
  static final exHeroName = _s(BldrTextV2.s24, _sb, BldrDetailsColorsV2.value); // 23
  static final exGroups = _s(BldrTextV2.s12, _m, BldrDetailsColorsV2.exMuted); // 12
  static final exMetaLabel = _s(BldrTextV2.s11, _sb, BldrDetailsColorsV2.exMuted); // 10
  static final exMetaValue = _s(BldrTextV2.s13, _m, BldrDetailsColorsV2.value); // 13
  static final exSetsValue = _s(BldrTextV2.s15, _sb, BldrDetailsColorsV2.value); // 14
  static final exHow = _s(BldrTextV2.s13, _sb, BldrDetailsColorsV2.value); // 13
  static final exStep = _s(BldrTextV2.s11, _m, BldrDetailsColorsV2.exMuted); // 11
  static final exTipLabel = _s(BldrTextV2.s11, _sb, BldrDetailsColorsV2.goldLabel); // 10
  static final exTipText = _s(BldrTextV2.s11, _m, BldrDetailsColorsV2.value); // 11
}

// Minha semana v2 (282:68 · 285:141 · 285:231 · 285:320 · 278:1487 · 278:1600 · 291:76)
abstract final class BldrWeekColorsV2 {
  static const headerButton = Color(0xFF2E2814);
  static const gold = Color(0xFFD4AD30);
  static const goldBrand = Color(0xFFD4AF37);
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF919191);
  static const cardBg = Color(0xFF181818);
  static const cardBorder = Color(0xFF363636);
  static const restBorder = Color(0xFF877545);
  static const todayChip = Color(0xFF40361A);
  static const chip = Color(0xFF262626);
  static const restChip = Color(0xFF242424);
  static const sheetText = Color(0xFFF7F7F7);
  static const sheetMuted = Color(0xFF9C9C9C);
  static const editChip = Color(0xFF212121);
  static const editMuted = Color(0xFF8C8C8C);
  static const dayRestBorder = Color(0xFF7A7A7A);
  static const track = Color(0xFF474747);
  static const snackBg = Color(0xFF171717);
  static const snackText = Color(0xFFFAFAFA);
  static const snackMuted = Color(0xFFA6A6A6);
}

abstract final class BldrWeekTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _sb = FontWeight.w600, _r = FontWeight.w400, _b = FontWeight.w700;
  static final title = _s(BldrTextV2.s17, _sb, BldrWeekColorsV2.text); // 18
  static final subtitle = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.muted); // 9
  static final range = _s(BldrTextV2.s15, _sb, BldrWeekColorsV2.text); // 15
  static final summary = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.muted); // 10
  static final instruction = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.gold); // 9
  static final day = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.muted); // 11
  static final dayToday = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.gold); // 11
  static final name = _s(BldrTextV2.s15, _sb, BldrWeekColorsV2.text); // 16
  static final restName = _s(BldrTextV2.s15, _sb, BldrWeekColorsV2.muted); // 16
  static final groups = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.muted); // 10
  static final chip = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.muted); // 9
  static final chipToday = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.gold); // 9
  static final add = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.gold); // 11
  static final section = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.muted); // 10
  static final editPlan = _s(BldrTextV2.s12, _sb, BldrWeekColorsV2.goldBrand); // 12
  static final extra = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.text); // 11
  static final footer = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.muted); // 10
  static final sheetSub = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.sheetMuted); // 11
  static final optionTitle = _s(BldrTextV2.s13, _sb, BldrWeekColorsV2.sheetText); // 13
  static final optionSub = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.sheetMuted); // 10
  static final pickName = _s(BldrTextV2.s15, _sb, BldrWeekColorsV2.sheetText); // 14
  static final destName = _s(BldrTextV2.s12, _sb, BldrWeekColorsV2.sheetText); // 12
  static final confirm = _s(BldrTextV2.s12, _b, BldrColorsV2.goldBright); // 12
  static final editLabel = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.editMuted); // 10
  static final editChip = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.editMuted); // 11
  static final editChipOn = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.gold); // 11
  static final editCount = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.gold); // 10
  static final save = _s(BldrTextV2.s15, _sb, BldrWeekColorsV2.goldBrand); // 14
  static final duration = _s(BldrTextV2.s12, _sb, BldrWeekColorsV2.gold); // 12
  static final snackTitle = _s(BldrTextV2.s15, _sb, BldrWeekColorsV2.snackText); // 14
  static final snackSub = _s(BldrTextV2.s11, _r, BldrWeekColorsV2.snackMuted); // 10
  static final undo = _s(BldrTextV2.s11, _sb, BldrWeekColorsV2.gold); // 11
}

// ── Comunidade v2 (Figma UAUhuDakeseJsEfb8ynv5h: 4:2, 4:108, 6:8) ──────────
abstract final class BldrCommunityColorsV2 {
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF7A7A7A);
  static const squadMuted = Color(0xFF787878);
  static const gold = BldrColorsV2.goldBright; // #E0B830
  static const goldBrand = BldrColorsV2.gold; // #D4AF37 — selo CLUB, foto
  static const divider = Color(0xFF242424);
  static const icon = Color(0xFF9A9A9A);
  static const shortcutFill = Color(0x337A7A7A); // #7A7A7A .2
  static const shortcutBorder = Color(0xFF585757);
  static const avatarBg = Color(0xFF080808);
  static const surface = Color(0xFF090909); // card do squad, botão seguir
  static const squadBorder = Color(0xE6403612); // rgba(64,54,18,.9)
  static const metricDivider = Color(0xB3332E1A); // rgba(51,46,26,.7)
  static const discoverBorder = Color(0xFF292929);
  static const moreBg = Color(0xFF0A0A0A);
  static const moreBorder = Color(0xFF333333);
  static const danger = Color(0xFFD94D4D);
  static const badge = Color(0xFFE53935);
  // Squads (86:842, 86:878, 96:830)
  static const fieldBg = Color(0xFF060606);
  static const fieldBorder = Color(0xFF252525);
  static const modeBorder = Color(0xFF2A2517);
  static const modeOnBg = Color(0xFF0E0D06);
  static const timeBg = Color(0xFF120F05);
  static const goalBg = Color(0xFF0A0A0A);
  static const chatMineBorder = Color(0xFF4D400F);
  static const dangerBright = Color(0xFFF24545);
  static const dangerBg = Color(0xFF1F0909);
  // Detalhe do post e perfil
  static const contentBg = Color(0xFF0B0B0B);
  static const inputBg = Color(0xFF090908);
  static const inputBorder = Color(0xFF242421);
  static const sendBg = Color(0xFF17140B);
  static const photoPlaceholder = Color(0xFF1C1811);
  // Criar publicação (50:892, 44:606, 32:354)
  static const composeMuted = Color(0xFF8F8F8F);
  static const composeBorder = Color(0xFF2E2E2E);
  static const pillBg = Color(0xFF030303);
  static const photoBorder = Color(0xFF33332E);
  static const photoActionBg = Color(0xFF0E0E0D);
  static const photoGradient = LinearGradient(
    colors: [Color(0xFF2E2514), Color(0xFF17140F), Color(0xFF0B0B0A)],
    stops: [0, 0.55, 1],
  );
}

/// Desafios (121:893, 141:941, 141:990, 143:1006, 121:960, 121:980, 121:1016).
abstract final class BldrChallengeColorsV2 {
  static const cardBorder = Color(0x54C9A227); // rgba(201,162,39,.33)
  static const rowBorder = Color(0xFF212121);
  static const cover = Color(0xFF171611);
  static const track = Color(0xFF292929);
  static const fill = Color(0xFFC9A227);
  static const fillStart = Color(0xFF7A641A);
  static const done = Color(0xFF33C766);
  static const pillBg = Color(0xFF1F1F1F);
  static const pillBorder = Color(0xFF474747);
  static const chipOnBg = Color(0x1FD4AF37); // rgba(212,175,55,.12)
  static const chipOffBorder = Color(0xFF404040);
  static const selectBg = Color(0xFF0B0B0B);
  static const selectBorder = Color(0x54D4AF37); // rgba(212,175,55,.33)
}

abstract final class BldrChallengeTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _b = FontWeight.w700, _sb = FontWeight.w600, _r = FontWeight.w400;
  static const _c = BldrCommunityColorsV2.text;
  static const _mu = BldrCommunityColorsV2.muted;
  static const _g = BldrChallengeColorsV2.fill;

  static final heading = _s(BldrTextV2.s24, _b, _c); // 22
  static final subtitle =
      _s(BldrTextV2.s12, _r, BldrCommunityColorsV2.composeMuted); // 12
  static final create = _s(BldrTextV2.s11, _sb, BldrCommunityColorsV2.goldBrand); // 11
  static final tabOn = _s(BldrTextV2.s13, _sb, _g); // 13
  static final tabOff = _s(BldrTextV2.s13, _r, _mu); // 13
  static final section = _s(BldrTextV2.s11, _sb, _mu); // 9-10
  static final featured = _s(BldrTextV2.s15, _b, _c); // 15
  static final cardTitle = _s(BldrTextV2.s13, _b, _c); // 13
  static final smallTitle = _s(BldrTextV2.s11, _b, _c); // 11
  static final meta = _s(BldrTextV2.s11, _r, _mu); // 8-9
  static final progress = _s(BldrTextV2.s12, _b, _c); // 12
  static final rank = _s(BldrTextV2.s11, _b, BldrCommunityColorsV2.gold); // 10
  static final goal = _s(BldrTextV2.s11, _sb, _g); // 10
  static final cta = _s(BldrTextV2.s11, _sb, BldrCommunityColorsV2.gold); // 9
  static final pill = _s(BldrTextV2.s11, _sb, _mu); // 8
  static final position = _s(BldrTextV2.s17, _b, _c); // 17
  static final positionSm = _s(BldrTextV2.s15, _b, _c); // 14
  static final sheetBody = _s(BldrTextV2.s11, _r, _c); // 10
  static final step = _s(BldrTextV2.s11, _sb, BldrCommunityColorsV2.gold); // 8
  static final pickerTitle = _s(BldrTextV2.s11, _sb, _c); // 11
  static final selectTitle = _s(BldrTextV2.s13, _sb, _c); // 13
  static final targetValue = _s(BldrTextV2.s20, _b, _c); // 20
  static final durationValue = _s(BldrTextV2.s15, _sb, _c); // 15
  static final chipOn = _s(BldrTextV2.s11, _sb, BldrCommunityColorsV2.goldBrand); // 9
  static final chipOff = _s(BldrTextV2.s11, _sb, _mu); // 9
  static final infoValue = _s(BldrTextV2.s11, _r, _c); // 10
  static final reviewValue = _s(BldrTextV2.s11, _b, _c); // 11
  static final reviewNote = _s(BldrTextV2.s11, _sb, _c); // 9
}

/// Ranking (121:1041).
abstract final class BldrRankingColorsV2 {
  static const chipOnBg = Color(0xFF1A170B);
  static const chipOnBorder = Color(0xBFD4AF37); // rgba(212,175,55,.75)
  static const chipOffBorder = Color(0xFF2E2E2E);
  static const mineBorder = Color(0x73D4AF37); // rgba(212,175,55,.45)
  static const mineBg = Color(0xFF131106);
  static const badgeOff = Color(0xFF2B2B2B);
  static const badgeOnText = Color(0xFF080808);
}

abstract final class BldrRankingTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _b = FontWeight.w700, _sb = FontWeight.w600, _r = FontWeight.w400;
  static const _c = BldrCommunityColorsV2.text;
  static const _mu = Color(0xFF757575);
  static const _g = BldrCommunityColorsV2.goldBrand;

  static final heading = _s(BldrTextV2.s24, _b, _c); // 24
  static final subtitle = _s(BldrTextV2.s12, _r, _mu); // 12
  static final tabOn = _s(BldrTextV2.s12, _sb, _g); // 12
  static final label = _s(BldrTextV2.s11, _sb, _mu); // 9
  static final chipOn = _s(BldrTextV2.s11, _sb, _g); // 10
  static final chipOff = _s(BldrTextV2.s11, _r, _mu); // 10
  static final mineLabel = _s(BldrTextV2.s11, _sb, _g); // 9
  static final minePos = _s(BldrTextV2.s24, _b, _c); // 22
  static final mineValue = _s(BldrTextV2.s15, _sb, _g); // 14
  static final badge = _s(BldrTextV2.s11, _b, _c); // 9
  static final badgeFirst =
      _s(BldrTextV2.s11, _b, BldrRankingColorsV2.badgeOnText); // 9
  static final initials = _s(BldrTextV2.s17, _sb, BldrCommunityColorsV2.gold); // 16
  static final initialsSm = _s(BldrTextV2.s12, _sb, BldrCommunityColorsV2.gold); // 12
  static final podiumName = _s(BldrTextV2.s11, _sb, _c); // 11
  static final podiumNameFirst = _s(BldrTextV2.s12, _sb, _c); // 12
  static final handle = _s(BldrTextV2.s11, _r, _mu); // 9
  static final podiumValue = _s(BldrTextV2.s11, _b, _c); // 11
  static final podiumValueFirst = _s(BldrTextV2.s13, _b, _g); // 13
  static final rowPos = _s(BldrTextV2.s12, _b, _mu); // 12
  static final rowPosMine = _s(BldrTextV2.s12, _b, _g); // 12
  static final rowName = _s(BldrTextV2.s11, _sb, _c); // 11
  static final rowValue = _s(BldrTextV2.s11, _sb, _c); // 11
  static final rowValueMine = _s(BldrTextV2.s11, _sb, _g); // 11
  static final lock = _s(BldrTextV2.s11, _sb, _c); // 11
}

/// Notificações (121:1128) e posts privados (121:827).
abstract final class BldrNotificationColorsV2 {
  static const divider = Color(0xFF212121);
  static const actionBg = Color(0xFF120F06);
  static const actionBorder = Color(0x8CE0B830); // rgba(224,184,48,.55)
}

abstract final class BldrNotificationTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _sb = FontWeight.w600, _r = FontWeight.w400;
  static const _c = BldrCommunityColorsV2.text;
  static const _mu = Color(0xFF757575);
  static const _g = BldrCommunityColorsV2.gold;

  static final markAll = _s(BldrTextV2.s11, _sb, _g); // 10
  static final tabOn = _s(BldrTextV2.s11, _sb, _g); // 11
  static final tabOff = _s(BldrTextV2.s11, _r, _mu); // 11
  static final group = _s(BldrTextV2.s11, _sb, _mu); // 9
  static final titleUnread = _s(BldrTextV2.s11, _sb, _c); // 11
  static final title = _s(BldrTextV2.s11, _r, _c); // 11
  static final meta = _s(BldrTextV2.s11, _r, _mu); // 9
  static final action = _s(BldrTextV2.s11, _sb, _g); // 9
  static final subtitle = _s(BldrTextV2.s11, _r, BldrCommunityColorsV2.muted); // 9
}

abstract final class BldrCommunityTextV2 {
  static TextStyle _s(double step, FontWeight w, Color c) =>
      BldrTextV2.scale(step, w, c);
  static const _b = FontWeight.w700,
      _sb = FontWeight.w600,
      _m = FontWeight.w500,
      _r = FontWeight.w400;
  static const _c = BldrCommunityColorsV2.text;
  static const _mu = BldrCommunityColorsV2.muted;
  static const _g = BldrCommunityColorsV2.gold;
  static const _sm = BldrCommunityColorsV2.squadMuted;

  static final title = _s(BldrTextV2.s28, _b, _c); // 27
  static final tabOn = _s(BldrTextV2.s11, _b, _g); // 11
  static final tabOff = _s(BldrTextV2.s11, _m, _mu); // 11
  // Post
  static final initials = _s(BldrTextV2.s11, _b, _g); // 9
  static final name = _s(BldrTextV2.s12, _b, _c); // 12
  static final meta = _s(BldrTextV2.s11, _r, _mu); // 9
  static final follow = _s(BldrTextV2.s11, _b, _g); // 8
  static final more = _s(BldrTextV2.s12, _b, _mu); // 12
  static final body = _s(BldrTextV2.s11, _r, _c); // 11
  static final type = _s(BldrTextV2.s11, _b, _g); // 9
  static final postTitle = _s(BldrTextV2.s15, _b, _c); // 15
  static final metrics = _s(BldrTextV2.s11, _m, _mu); // 9
  static final source = _s(BldrTextV2.s11, _sb, _mu); // 8
  static final value = _s(BldrTextV2.s17, _b, _c); // 18
  static final valueLabel = _s(BldrTextV2.s11, _sb, _mu); // 8
  static final count = _s(BldrTextV2.s11, _m, _mu); // 8
  static final countOn = _s(BldrTextV2.s11, _m, _c); // 8
  // Squads
  static final eyebrow = _s(BldrTextV2.s11, _b, _g); // 9
  static final squadName = _s(BldrTextV2.s20, _b, _c); // 21
  static final squadMeta = _s(BldrTextV2.s11, _m, _sm); // 10
  static final metricValue = _s(BldrTextV2.s20, _b, _g); // 20
  static final metricLabel = _s(BldrTextV2.s11, _b, _sm); // 9
  static final plusLabel = _s(BldrTextV2.s11, _b, _sm); // 9
  static final section = _s(BldrTextV2.s11, _b, _sm); // 10
  static final discoverTitle = _s(BldrTextV2.s15, _b, _c); // 14
  static final discoverSub = _s(BldrTextV2.s11, _r, _sm); // 9
  static final chevron = _s(BldrTextV2.s20, _r, _g); // 22
  static final activityName = _s(BldrTextV2.s11, _b, _c); // 11
  static final activityMeta = _s(BldrTextV2.s11, _r, _sm); // 8
  static final activityBody = _s(BldrTextV2.s11, _r, _c); // 10
  static final cta = _s(BldrTextV2.s11, _b, _g); // 9
  // Sheet de ações (6:70)
  static final sheetHandle = _s(BldrTextV2.s11, _m, _mu); // 9
  static final rowTitle = _s(BldrTextV2.s12, _sb, _c); // 12
  static final rowTitleDanger =
      _s(BldrTextV2.s12, _sb, BldrCommunityColorsV2.danger); // 12
  static final rowSub = _s(BldrTextV2.s11, _r, _mu); // 9
  static final emoji = _s(BldrTextV2.s28, _r, _c);
  // Sheets de conteúdo (22:254, 22:391, 22:525)
  static final sheetSub = _s(BldrTextV2.s11, _r, _mu); // 9
  static final sheetMetric = _s(BldrTextV2.s17, _b, _c); // 17
  static final exercise = _s(BldrTextV2.s11, _sb, _c); // 11
  static final detailLabel = _s(BldrTextV2.s11, _m, _c); // 10
  static final detailValue = _s(BldrTextV2.s11, _sb, _c); // 10
  static final prValue = _s(BldrTextV2.s28, _b, _c); // 26
  static final prDelta = _s(BldrTextV2.s11, _sb, _g); // 10
  static final historyDate = _s(BldrTextV2.s11, _m, _mu); // 10
  // Squads
  static final sqHeading = _s(BldrTextV2.s20, _b, _c); // 22
  static final sqTitle = _s(BldrTextV2.s17, _b, _c); // 18
  static final sqLabel = _s(BldrTextV2.s11, _b, _mu); // 8
  static final sqInput = _s(BldrTextV2.s12, _r, _c); // 10
  static final sqHint = _s(BldrTextV2.s12, _r, _mu); // 10
  static final sqModeOff = _s(BldrTextV2.s11, _b, _mu); // 10
  static final sqModeOn = _s(BldrTextV2.s11, _b, _c); // 10
  static final sqModeSubOn = _s(BldrTextV2.s11, _r, _g); // 8
  static final sqTab = _s(BldrTextV2.s11, _b, _sm); // 9
  static final sqMetric = _s(BldrTextV2.s20, _b, _g); // 19
  static final sqTime = _s(BldrTextV2.s11, _b, _g); // 10
  static final sqGoal = _s(BldrTextV2.s15, _b, _c); // 14
  static final sqRankPos = _s(BldrTextV2.s11, _b, _g); // 11
  static final sqRankPosOff = _s(BldrTextV2.s11, _b, _sm); // 11
  static final sqRankName = _s(BldrTextV2.s11, _b, _c); // 10
  static final sqDanger = _s(BldrTextV2.s11, _sb, BldrCommunityColorsV2.dangerBright); // 11
  static final sqDangerLabel =
      _s(BldrTextV2.s11, _b, BldrCommunityColorsV2.dangerBright); // 8
  static final sqDangerCta = _s(BldrTextV2.s11, _b, BldrCommunityColorsV2.danger); // 8
  static final sqBubble = _s(BldrTextV2.s12, _r, _c); // 10
  static final sqBubbleTime = _s(BldrTextV2.s11, _r, _mu); // 7
  static final sqBubbleTimeMine = _s(BldrTextV2.s11, _r, _g); // 7
  // Detalhe do post (52:802) e perfil social (56:855)
  static final backIcon = _s(BldrTextV2.s28, _r, _c); // 26
  static final detailTitle = _s(BldrTextV2.s20, _b, _c); // 20
  static final detailAuthor = _s(BldrTextV2.s12, _sb, _c); // 12
  static final contentTitle = _s(BldrTextV2.s17, _b, _c); // 18
  static final contentMetric = _s(BldrTextV2.s17, _b, _c); // 16
  static final commentName = _s(BldrTextV2.s11, _sb, _c); // 9
  static final commentBody = _s(BldrTextV2.s11, _r, _c); // 9
  static final commentAction = _s(BldrTextV2.s11, _sb, _mu); // 7
  static final profileHandle = _s(BldrTextV2.s17, _b, _c); // 18
  static final profileName = _s(BldrTextV2.s17, _b, _c); // 17
  static final profileInitials = _s(BldrTextV2.s13, _b, _g); // 13
  static final profileFollowers = _s(BldrTextV2.s11, _sb, _c); // 9
  static final profileFollowing = _s(BldrTextV2.s11, _sb, _mu); // 9
  static final perfValue = _s(BldrTextV2.s20, _b, _c); // 20
  static final achievement = _s(BldrTextV2.s11, _sb, _c); // 7
  // Criar publicação
  static const _cm = BldrCommunityColorsV2.composeMuted;
  static final composeHint = _s(BldrTextV2.s15, _r, _cm); // 15
  static final composeInput = _s(BldrTextV2.s15, _r, _c);
  static final composeTab = _s(BldrTextV2.s11, _m, _cm); // 9
  static final composeTabOn = _s(BldrTextV2.s11, _sb, _g); // 9
  static final composeEyebrow = _s(BldrTextV2.s11, _b, _g); // 8
  static final composeMeta = _s(BldrTextV2.s11, _m, _cm); // 9
  static final composeAction = _s(BldrTextV2.s11, _sb, _c); // 9
  static final composeRemove = _s(BldrTextV2.s11, _b, _cm); // 7
  static final composePhoto = _s(BldrTextV2.s11, _sb, _c); // 10
}

abstract final class BldrCommunityV2 {
  static const double pageX = 22;
  static const double avatar = 38;
  static const double avatarRing = 0.9;
  static const double shortcut = 22;
  static const double shortcutIcon = 14;
  static const double shortcutGap = 7;
  static const double fab = 52;
  static const double photoRadius = 18;
  static const double photoHeight = 190;
  static const double squadRadius = 20;
  static const double ctaRadius = 17;
  static const double followHeight = 26;
}
