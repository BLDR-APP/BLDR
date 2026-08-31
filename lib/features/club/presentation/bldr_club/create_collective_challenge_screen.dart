import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Criação deliberadamente limitada aos três pipelines que o servidor aceita.
class CreateCollectiveChallengeScreen extends StatefulWidget {
  const CreateCollectiveChallengeScreen({super.key});

  @override
  State<CreateCollectiveChallengeScreen> createState() =>
      _CreateCollectiveChallengeScreenState();
}

class _CreateCollectiveChallengeScreenState
    extends State<CreateCollectiveChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  String _type = 'xp_total';
  DateTime _endsAt = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  String get _targetLabel => switch (_type) {
        'xp_total' => 'Meta de XP total',
        'workouts' => 'Meta de treinos',
        _ => 'Meta de dias de streak',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final result = await getIt<CreateCollectiveChallenge>()(
      NewCollectiveChallenge(
        title: _title.text.trim(),
        description: _description.text.trim(),
        challengeType: _type,
        targetValue: int.parse(_target.text),
        rewardXp: 0,
        endsAt: _endsAt.toUtc(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) => Navigator.pop(context, true),
      onFailure: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
    );
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null && mounted) setState(() => _endsAt = date);
  }

  @override
  Widget build(BuildContext context) => BldrBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text('Criar desafio', style: BldrText.screenTitle),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(BldrSpacing.pageX),
                children: [
                  Text('Desafio coletivo', style: BldrText.sectionTitle),
                  const SizedBox(height: 8),
                  Text(
                      'O progresso é calculado pelo BLDR. Escolha uma meta clara para a comunidade.',
                      style: BldrText.description),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _title,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                            ? 'Use ao menos 3 caracteres.'
                            : null,
                  ),
                  TextFormField(
                    controller: _description,
                    maxLength: 280,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'xp_total', child: Text('XP total')),
                      DropdownMenuItem(
                          value: 'workouts', child: Text('Treinos concluídos')),
                      DropdownMenuItem(
                          value: 'streak',
                          child: Text('Maior streak durante o desafio')),
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: _targetLabel),
                    validator: (value) => int.tryParse(value ?? '') == null ||
                            int.parse(value!) <= 0
                        ? 'Informe uma meta maior que zero.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Termina em'),
                    subtitle: Text(
                        '${_endsAt.day.toString().padLeft(2, '0')}/${_endsAt.month.toString().padLeft(2, '0')}/${_endsAt.year}'),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickEndDate,
                  ),
                  const SizedBox(height: 28),
                  BldrPrimaryButton(
                    label: _saving ? 'Criando…' : 'Criar desafio',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
