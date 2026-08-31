import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_thread.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// User-facing management for persistent HAVOK context. This intentionally
/// displays only explicit memories, never live performance/health metrics.
class HavokMemorySheet extends StatefulWidget {
  const HavokMemorySheet({super.key});

  @override
  State<HavokMemorySheet> createState() => _HavokMemorySheetState();
}

class _HavokMemorySheetState extends State<HavokMemorySheet> {
  bool _loading = true;
  List<HavokMemory> _memories = const [];

  static const _labels = <String, String>{
    'goal': 'Objetivos',
    'training_preference': 'Treino',
    'nutrition_preference': 'Nutrição',
    'routine': 'Rotina',
    'preference': 'Preferências',
    'constraint': 'Restrições',
    'equipment': 'Equipamentos',
    'context': 'Outros',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetHavokMemories>()();
    if (!mounted) return;
    setState(() {
      _memories = result.valueOrNull ?? const [];
      _loading = false;
    });
  }

  Future<void> _forget(HavokMemory memory) async {
    await getIt<ForgetHavokMemory>()(memory.id);
    await _load();
  }

  Future<void> _edit(HavokMemory memory) async {
    final controller = TextEditingController(text: memory.displayValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BldrColors.surface,
        title: const Text('Editar memória', style: BldrText.sectionTitle),
        content: TextField(
            controller: controller, autofocus: true, style: BldrText.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await getIt<UpdateHavokMemory>()(memory, value);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BldrColors.surface,
        title: const Text('Limpar memórias?', style: BldrText.sectionTitle),
        content: const Text(
            'O HAVOK deixará de usar todas as suas preferências e contextos salvos.',
            style: BldrText.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limpar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await getIt<ClearHavokMemories>()();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<HavokMemory>>{};
    for (final memory in _memories) {
      (groups[memory.category] ??= []).add(memory);
    }
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      appBar: AppBar(
        backgroundColor: BldrColors.bgBase,
        title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Memória HAVOK', style: BldrText.sectionTitle),
              Text('O que seu coach lembra sobre você',
                  style: TextStyle(fontSize: 11, color: BldrColors.textMuted)),
            ]),
        actions: [
          IconButton(
              onPressed: _memories.isEmpty ? null : _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined))
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BldrColors.goldBright))
          : _memories.isEmpty
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                          'Ainda não há memórias salvas. Você pode contar suas preferências ao HAVOK quando quiser.',
                          textAlign: TextAlign.center,
                          style: BldrText.description)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(_labels[entry.key] ?? 'Outros',
                              style: BldrText.sectionTitle
                                  .copyWith(fontSize: 15))),
                      ...entry.value.map((memory) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: BldrGlassCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text(memory.key, style: BldrText.cardTitle),
                              subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(memory.displayValue,
                                      style: BldrText.description)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) => action == 'edit'
                                    ? _edit(memory)
                                    : _forget(memory),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Editar')),
                                  PopupMenuItem(
                                      value: 'forget', child: Text('Esquecer'))
                                ],
                              ),
                            ),
                          ))),
                    ]
                  ],
                ),
    );
  }
}
