import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(TablerIcons.chevron_left,
                color: BldrColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Ranking', style: BldrText.screenTitle),
        ),
        body: const Center(
          child: Text('Ranking — Em breve',
              style: TextStyle(color: BldrColors.textSecondary)),
        ),
      ),
    );
  }
}
