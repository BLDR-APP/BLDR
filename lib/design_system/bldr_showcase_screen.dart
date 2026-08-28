// DESCARTÁVEL — vitrine dos componentes do design system.
//
// Existe só para conferência visual antes de aplicar em tela real.
// Não é referenciada por nenhuma tela do app; a única entrada é a rota
// temporária AppRoutes.bldrShowcase ('/__bldr-showcase').
//
// APAGAR junto com a rota quando o redesign começar a valer nas telas.

import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class BldrShowcaseScreen extends StatefulWidget {
  const BldrShowcaseScreen({super.key});

  @override
  State<BldrShowcaseScreen> createState() => _BldrShowcaseScreenState();
}

class _BldrShowcaseScreenState extends State<BldrShowcaseScreen> {
  int _segment = 0;
  int _navIndex = 0;
  bool _chipAtivo = true;

  @override
  Widget build(BuildContext context) {
    return BldrScreen(
      navBar: BldrNavBar(
        selectedIndex: _navIndex,
        onChanged: (i) => setState(() => _navIndex = i),
        onClubTap: () {},
        clubLogo: const Icon(Icons.shield_outlined,
            color: BldrColors.goldBright, size: 26),
      ),
      // BldrScreen já é rolável e já aplica navClearance no rodapé —
      // o body precisa ser não-rolável, senão vira viewport aninhado.
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX,
          24,
          BldrSpacing.pageX,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text('Design system', style: BldrText.screenTitle),
          const SizedBox(height: 4),
          Text(
            'Vitrine descartável — 10 componentes, dados fictícios',
            style: BldrText.label,
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 1. BldrHeroCard ──────────────────────────────────────────
          _Legenda('1 · BldrHeroCard'),
          BldrHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hoje · Legs', style: BldrText.label),
                const SizedBox(height: 6),
                Text('Pernas + glúteos', style: BldrText.kpiMd),
                const SizedBox(height: 4),
                Text('8 exercícios · ~50 min', style: BldrText.meta),
                const SizedBox(height: BldrSpacing.padCard),
                BldrPrimaryButton(
                  label: 'Iniciar treino',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 2. BldrGlassCard ─────────────────────────────────────────
          _Legenda('2 · BldrGlassCard'),
          BldrGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peso alvo', style: BldrText.cardTitle),
                const SizedBox(height: 8),
                Text('78 kg', style: BldrText.kpiLg),
                const SizedBox(height: 4),
                Text('meta 80 kg', style: BldrText.meta),
              ],
            ),
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 3. BldrPrimaryButton ─────────────────────────────────────
          _Legenda('3 · BldrPrimaryButton (com e sem ícone, e desabilitado)'),
          BldrPrimaryButton(label: 'Salvar', onPressed: () {}),
          const SizedBox(height: BldrSpacing.gapCard),
          BldrPrimaryButton(
            label: 'Adicionar alimento',
            icon: Icons.add_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: BldrSpacing.gapCard),
          const BldrPrimaryButton(label: 'Sem onPressed (desabilitado)'),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 4. BldrChip ──────────────────────────────────────────────
          _Legenda('4 · BldrChip (ativo alterna ao tocar)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BldrChip(
                label: 'Streak 12 dias',
                icon: Icons.local_fire_department_outlined,
                active: _chipAtivo,
                onTap: () => setState(() => _chipAtivo = !_chipAtivo),
              ),
              const BldrChip(label: 'Treinos/mês 14'),
              const BldrChip(label: 'Tempo total 9h'),
              const BldrChip(label: 'Conquistas 7'),
            ],
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 5. BldrSegmentedControl ──────────────────────────────────
          _Legenda('5 · BldrSegmentedControl'),
          BldrSegmentedControl(
            segments: const ['Geral', 'Corpo', 'Treinos', 'Nutrição'],
            selectedIndex: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 6. BldrProgressBar ───────────────────────────────────────
          _Legenda('6 · BldrProgressBar (sólida, gradiente, vazia, cheia)'),
          BldrGlassCard(
            child: Column(
              children: [
                const BldrProgressBar(value: 0.62),
                const SizedBox(height: 14),
                const BldrProgressBar(value: 0.78, gradient: true, height: 8),
                const SizedBox(height: 14),
                const BldrProgressBar(value: 0),
                const SizedBox(height: 14),
                const BldrProgressBar(value: 1),
              ],
            ),
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 7. BldrListRow ───────────────────────────────────────────
          _Legenda('7 · BldrListRow'),
          BldrGlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                BldrListRow(
                  icon: Icons.person_outline,
                  title: 'Editar perfil',
                  subtitle: 'Nome, telefone, foto',
                  onTap: () {},
                ),
                BldrListRow(
                  icon: Icons.card_membership_outlined,
                  title: 'Gerenciar assinatura',
                  subtitle: 'Renova em 12 de agosto',
                  onTap: () {},
                ),
                BldrListRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificações',
                  trailing: Text('Ativadas',
                      style: BldrText.meta
                          .copyWith(color: BldrColors.goldBright)),
                ),
              ],
            ),
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 8. BldrEmptyState ────────────────────────────────────────
          _Legenda('8 · BldrEmptyState'),
          const BldrEmptyState(
            icon: Icons.fitness_center_outlined,
            title: 'Nenhum treino criado',
            instruction: 'Crie o primeiro treino ou comece a partir de uma foto.',
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 9. BldrCarousel ──────────────────────────────────────────
          _Legenda('9 · BldrCarousel (arraste na horizontal)'),
          BldrCarousel(
            itemWidth: 150,
            height: 168,
            children: List.generate(5, (i) {
              return BldrGlassCard(
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Text('Push ${String.fromCharCode(65 + i)}',
                        style: BldrText.cardTitle),
                    const SizedBox(height: 3),
                    Text('${6 + i} exercícios', style: BldrText.meta),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: BldrSpacing.gapSection),

          // ── 10. BldrNavBar ───────────────────────────────────────────
          _Legenda('10 · BldrNavBar — fixa no rodapé desta tela'),
          Text(
            'Índice selecionado: $_navIndex. Toque nos ícones abaixo.',
            style: BldrText.meta,
          ),
          ],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(texto.toUpperCase(), style: BldrText.label),
    );
  }
}
