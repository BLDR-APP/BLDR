import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/features/profile/domain/usecases/feedback_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

enum _Step { selectType, message, screenshot, sending, done, error }

class FeedbackScreen extends StatefulWidget {
  final String? tipoInicial;
  const FeedbackScreen({super.key, this.tipoInicial});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  String? _tipo;
  _Step _step = _Step.selectType;
  String? _errorMessage;
  String? _protocolo;
  String? _screenshotPath;
  String? _appVersion;
  String? _userName;

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      _addBldrMessage(l10n.feedback_bldr_greeting);
      _addBldrMessage(l10n.feedback_bldr_select_type);
      if (widget.tipoInicial != null) {
        _selectType(widget.tipoInicial!);
      }
    });
  }

  Future<void> _loadMeta() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    if (meta != null && mounted) {
      setState(() => _userName = meta['full_name'] as String? ?? meta['name'] as String?);
    }
  }

  void _addBldrMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isBldr: true));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isBldr: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectType(String tipo) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _tipo = tipo;
      _step = _Step.message;
    });
    final label = switch (tipo) {
      'bug' => '🐛 ${l10n.feedback_chip_bug}',
      'sugestao' => '💡 ${l10n.feedback_chip_suggestion}',
      'reclamacao' => '😤 ${l10n.feedback_chip_complaint}',
      _ => '💬 ${l10n.feedback_chip_other}',
    };
    _addUserMessage(label);
    final prompt = switch (tipo) {
      'bug' => l10n.feedback_bldr_bug_step1,
      'sugestao' => l10n.feedback_bldr_suggestion_step1,
      'reclamacao' => l10n.feedback_bldr_complaint_step1,
      _ => l10n.feedback_bldr_other_step1,
    };
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _addBldrMessage(prompt);
    });
    _focusNode.requestFocus();
  }

  void _submitMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    _addUserMessage(text);
    _controller.clear();
    setState(() => _step = _Step.screenshot);
    final prompt = switch (_tipo) {
      'bug' => l10n.feedback_bldr_bug_step2,
      'sugestao' => l10n.feedback_bldr_suggestion_step2,
      'reclamacao' => l10n.feedback_bldr_complaint_step2,
      _ => l10n.feedback_bldr_other_step2,
    };
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _addBldrMessage(prompt);
    });
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _screenshotPath = file.path);
    }
  }

  void _skipScreenshot() {
    _sendFeedback(null);
  }

  Future<void> _sendWithScreenshot() async {
    String? url;
    if (_screenshotPath != null) {
      url = await _uploadScreenshot(_screenshotPath!);
    }
    _sendFeedback(url);
  }

  Future<String?> _uploadScreenshot(String path) async {
    try {
      final bytes = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: 800,
        minHeight: 0,
        quality: 70,
      );
      if (bytes == null) return null;
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$filename';
      await Supabase.instance.client.storage
          .from('feedback-screenshots')
          .uploadBinary(storagePath, Uint8List.fromList(bytes),
              fileOptions: const FileOptions(contentType: 'image/jpeg'));
      return Supabase.instance.client.storage
          .from('feedback-screenshots')
          .getPublicUrl(storagePath);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendFeedback(String? screenshotUrl) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _step = _Step.sending);
    _addBldrMessage(l10n.feedback_bldr_sending);

    final messageText = _messages
        .where((m) => !m.isBldr)
        .skip(1)
        .map((m) => m.text)
        .join('\n');

    final result = await GetIt.instance<SendFeedback>()(
      tipo: _tipo!,
      mensagem: messageText,
      screenshotUrl: screenshotUrl,
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (value) {
        setState(() {
          _step = _Step.done;
          _protocolo = value.protocolo;
        });
        _addBldrMessage(l10n.feedback_bldr_success);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _addBldrMessage(l10n.feedback_bldr_protocol(_protocolo!));
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _addBldrMessage(l10n.feedback_bldr_thanks);
            });
          }
        });
      },
      onFailure: (failure) {
        setState(() {
          _step = _Step.error;
          _errorMessage = failure is NetworkFailure
              ? 'Sem conexão com a internet.'
              : failure.message;
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    final metaLine = [
      if (_appVersion != null) 'v$_appVersion',
      platform,
      if (_userName != null) _userName!,
    ].join(' · ');

    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      appBar: AppBar(
        backgroundColor: BldrColors.bgBase,
        elevation: 0,
        title: Text(
          l10n.feedback_title,
          style: const TextStyle(
            color: BldrColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: BldrColors.textPrimary),
      ),
      body: Column(
        children: [
          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _BubbleWidget(message: _messages[i]),
            ),
          ),

          // Type chips (only when in selectType step)
          if (_step == _Step.selectType) _TypeChipsBar(onSelect: _selectType),

          // Screenshot preview + actions
          if (_step == _Step.screenshot) _ScreenshotBar(
            path: _screenshotPath,
            onPick: _pickScreenshot,
            onRemove: () => setState(() => _screenshotPath = null),
            onSkip: _skipScreenshot,
            onSend: _sendWithScreenshot,
            l10n: l10n,
          ),

          // Error bar
          if (_step == _Step.error)
            _ErrorBar(
              message: _errorMessage ?? 'Erro desconhecido.',
              onRetry: () {
                setState(() => _step = _Step.screenshot);
                _sendWithScreenshot();
              },
              l10n: l10n,
            ),

          // Input
          if (_step == _Step.message || _step == _Step.sending || _step == _Step.done)
            _InputBar(
              controller: _controller,
              focusNode: _focusNode,
              enabled: _step == _Step.message,
              onSend: _submitMessage,
              l10n: l10n,
            ),

          // Metadata footer
          if (metaLine.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4),
              child: Text(
                metaLine,
                style: const TextStyle(
                  color: BldrColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isBldr;
  _ChatMessage({required this.text, required this.isBldr});
}

// ─── Bubble widget ────────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final _ChatMessage message;
  const _BubbleWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isBldr) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B avatar
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: BldrColors.goldTint,
                border: Border.all(color: BldrColors.goldBorder),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'B',
                style: TextStyle(
                  color: BldrColors.goldBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: BldrColors.surface,
                  border: Border.all(color: BldrColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: BldrColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      );
    }
    // User bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: BldrColors.goldTintChip,
                border: Border.all(color: BldrColors.goldBorderChip),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: BldrColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type chips bar ───────────────────────────────────────────────────────────

class _TypeChipsBar extends StatelessWidget {
  final void Function(String) onSelect;
  const _TypeChipsBar({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = [
      ('bug', '🐛', l10n.feedback_chip_bug),
      ('sugestao', '💡', l10n.feedback_chip_suggestion),
      ('reclamacao', '😤', l10n.feedback_chip_complaint),
      ('outro', '💬', l10n.feedback_chip_other),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((c) {
          return GestureDetector(
            onTap: () => onSelect(c.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: BldrColors.goldTintChip,
                border: Border.all(color: BldrColors.goldBorderChip),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${c.$2} ${c.$3}',
                style: const TextStyle(
                  color: BldrColors.goldBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Input bar ───────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;
  final AppLocalizations l10n;
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
    required this.l10n,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() => _count = widget.controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showCounter = _count > 400;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showCounter)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.l10n.feedback_chars_remaining(_count),
                style: const TextStyle(color: BldrColors.textMuted, fontSize: 11),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  maxLength: 500,
                  maxLines: null,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  style: const TextStyle(color: BldrColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.l10n.feedback_hint_message,
                    hintStyle: const TextStyle(color: BldrColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.enabled && _count > 0 ? widget.onSend : null,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.enabled && _count > 0
                        ? BldrColors.goldSolid
                        : BldrColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.enabled && _count > 0
                          ? BldrColors.goldBright
                          : BldrColors.border,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: widget.enabled && _count > 0
                        ? BldrColors.bgBase
                        : BldrColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Screenshot bar ───────────────────────────────────────────────────────────

class _ScreenshotBar extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onSkip;
  final VoidCallback onSend;
  final AppLocalizations l10n;

  const _ScreenshotBar({
    required this.path,
    required this.onPick,
    required this.onRemove,
    required this.onSkip,
    required this.onSend,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path != null) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(path!), width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onRemove,
                  child: Text(l10n.feedback_remove_screenshot,
                      style: const TextStyle(color: BldrColors.danger, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (path == null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.image_outlined, size: 16, color: BldrColors.goldBright),
                    label: Text(l10n.feedback_add_screenshot,
                        style: const TextStyle(color: BldrColors.goldBright, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: BldrColors.goldBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              if (path == null) const SizedBox(width: 10),
              if (path == null)
                OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BldrColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                  child: Text(l10n.feedback_skip,
                      style: const TextStyle(color: BldrColors.textSecondary, fontSize: 13)),
                ),
              if (path != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BldrColors.goldSolid,
                      foregroundColor: BldrColors.bgBase,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.feedback_send,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error bar ────────────────────────────────────────────────────────────────

class _ErrorBar extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ErrorBar({required this.message, required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: BldrColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: BldrColors.danger, fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.feedback_error_retry,
                style: const TextStyle(color: BldrColors.goldBright, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
