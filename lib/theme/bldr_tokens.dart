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
