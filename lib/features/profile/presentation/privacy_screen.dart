import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/profile/domain/entities/privacy_settings.dart';
import 'package:bldr_fitness/features/profile/domain/usecases/privacy_usecases.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _cardBg = Color(0xFF111111);

  bool _loading = true;
  bool _saving = false;

  // Identidade
  bool _useDisplayName = false;
  final _displayNameCtrl = TextEditingController();
  bool _photoPublic = true;

  // Feed
  bool _feedVisible = true;
  bool _reactionsEnabled = true;

  // Ranking
  bool _rankingVisible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = getIt<GetCurrentUser>()()?.id;
    if (uid == null) return;
    final result = await getIt<GetPrivacySettings>()(uid);
    result.fold(
      onFailure: (_) => setState(() => _loading = false),
      onSuccess: (s) => setState(() {
        _loading = false;
        _useDisplayName = s.displayName != null && s.displayName!.isNotEmpty;
        _displayNameCtrl.text = s.displayName ?? '';
        _photoPublic = s.photoVisibility != 'squad';
        _feedVisible = s.feedVisible;
        _reactionsEnabled = s.reactionsEnabled;
        _rankingVisible = s.rankingVisible;
      }),
    );
  }

  Future<void> _save() async {
    final dn = _displayNameCtrl.text.trim();
    if (_useDisplayName && dn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.privacy_nickname_required),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _saving = true);
    final uid = getIt<GetCurrentUser>()()?.id;
    if (uid == null) return;

    final settings = PrivacySettings(
      displayName: _useDisplayName ? dn : null,
      photoVisibility: _photoPublic ? 'public' : 'squad',
      feedVisible: _feedVisible,
      reactionsEnabled: _reactionsEnabled,
      rankingVisible: _rankingVisible,
    );

    final result = await getIt<SavePrivacySettings>()(uid, settings);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(f.message),
        backgroundColor: Colors.redAccent,
      )),
      onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.privacy_saved),
        backgroundColor: Colors.green,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(l10n.privacy_title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _gold)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(l10n.privacy_save_btn,
                  style:
                      const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionLabel(l10n.privacy_section_identity),
                _card([
                  _toggleRow(
                    title: l10n.privacy_name_toggle_title,
                    subtitle: _useDisplayName
                        ? l10n.privacy_name_active_label
                        : l10n.privacy_name_inactive_subtitle,
                    value: _useDisplayName,
                    onChanged: (v) => setState(() {
                      _useDisplayName = v;
                      if (!v) _displayNameCtrl.clear();
                    }),
                    activeLabel: l10n.privacy_name_active_label,
                    inactiveLabel: l10n.privacy_name_inactive_label,
                  ),
                  if (_useDisplayName) ...[
                    const Divider(color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        controller: _displayNameCtrl,
                        maxLength: 20,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_À-ú ]')),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: l10n.privacy_nickname_hint,
                          hintStyle:
                              const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white10),
                  _toggleRow(
                    title: l10n.privacy_photo_toggle_title,
                    subtitle: _photoPublic
                        ? l10n.privacy_photo_active_subtitle
                        : l10n.privacy_photo_inactive_subtitle,
                    value: _photoPublic,
                    onChanged: (v) => setState(() => _photoPublic = v),
                    activeLabel: l10n.privacy_photo_active_label,
                    inactiveLabel: l10n.privacy_photo_inactive_label,
                    comingSoon: true,
                  ),
                ]),
                const SizedBox(height: 24),
                _sectionLabel(l10n.privacy_section_feed),
                _card([
                  _toggleRow(
                    title: l10n.privacy_feed_toggle_title,
                    subtitle: _feedVisible
                        ? l10n.privacy_feed_active_subtitle
                        : l10n.privacy_feed_inactive_subtitle,
                    value: _feedVisible,
                    onChanged: (v) => setState(() {
                      _feedVisible = v;
                      if (!v) _reactionsEnabled = false;
                    }),
                    activeLabel: l10n.privacy_yes,
                    inactiveLabel: l10n.privacy_no,
                    comingSoon: true,
                  ),
                  if (_feedVisible) ...[
                    const Divider(color: Colors.white10),
                    _toggleRow(
                      title: l10n.privacy_reactions_toggle_title,
                      subtitle: l10n.privacy_reactions_subtitle,
                      value: _reactionsEnabled,
                      onChanged: (v) =>
                          setState(() => _reactionsEnabled = v),
                      activeLabel: l10n.privacy_yes,
                      inactiveLabel: l10n.privacy_no,
                      comingSoon: true,
                    ),
                  ],
                ]),
                const SizedBox(height: 24),
                _sectionLabel(l10n.privacy_section_ranking),
                _card([
                  _toggleRow(
                    title: l10n.privacy_ranking_toggle_title,
                    subtitle: _rankingVisible
                        ? l10n.privacy_ranking_active_subtitle
                        : l10n.privacy_ranking_inactive_subtitle,
                    value: _rankingVisible,
                    onChanged: (v) =>
                        setState(() => _rankingVisible = v),
                    activeLabel: l10n.privacy_yes,
                    inactiveLabel: l10n.privacy_no,
                  ),
                ]),
                const SizedBox(height: 32),
                _legalCard(),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      );

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String activeLabel,
    required String inactiveLabel,
    bool comingSoon = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: _gold,
                ),
              ],
            ),
            if (comingSoon)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  'Esta preferência será aplicada em breve',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.28),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _legalCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.privacy_legal_text,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('https://www.bldrapp.com.br/privacidade');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
              child: Text(
                AppLocalizations.of(context)!.privacy_legal_link,
                style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      );
}
