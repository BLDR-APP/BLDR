import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class TribunalScreen extends StatefulWidget {
  final String arenaId;

  const TribunalScreen({super.key, required this.arenaId});

  @override
  State<TribunalScreen> createState() => _TribunalScreenState();
}

class _TribunalScreenState extends State<TribunalScreen> {
  static const gold = Color(0xFFD4AF37);
  late final String _myUserId = getIt<GetCurrentUser>()()!.id;
  final TextEditingController _textController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];
  String _validationType = 'photo';

  @override
  void initState() {
    super.initState();
    _loadValidationType();
    _fetchFeed();
  }

  Future<void> _loadValidationType() async {
    try {
      final result =
          await getIt<ArenaRepository>().validationType(widget.arenaId);
      final type = result.valueOrNull;
      if (mounted && type != null) {
        setState(() => _validationType = type);
      }
    } catch (e) {
      print("Erro ao carregar validation_type: $e");
    }
  }

  Future<void> _fetchFeed() async {

    try {
      final feedResult =
          await getIt<ArenaRepository>().tribunalFeed(widget.arenaId);
      final data = feedResult.valueOrNull ?? <Map<String, dynamic>>[];
      final profilesMap = {
        for (final p in data)
          if (p['user_profiles'] != null) p['user_id']: p['user_profiles']
      };

      final List<Map<String, dynamic>> processed = [];

      for (var post in data) {
        String? myVote;

        // MUDANÇA AQUI: Pegamos o placar direto do post (que você editou no banco)
        // Se estiver null, assume 0
        int validCount = post['votes_valid'] ?? 0;
        int fakeCount = post['votes_fake'] ?? 0;

        final votes = post['tribunal_votes'] as List;

        // O loop agora serve SÓ para descobrir se EU votei
        for(var v in votes) {
          if (v['voter_id'] == _myUserId) {
            myVote = v['vote_type'];
            break; // Achou meu voto, pode parar de procurar
          }
        }

        if (post['user_id'] == _myUserId) myVote = 'owner';

        final profile = profilesMap[post['user_id']];

        processed.add({
          ...post,
          'username': profile?['full_name'] ?? 'Agente',
          'avatar': profile?['avatar_url'],
          'my_vote': myVote,
          'votes_valid': validCount,
          'votes_fake': fakeCount,
        });
      }

      if (mounted) {
        setState(() {
          _posts = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro feed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNÇÃO QUE FALTAVA ---
  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear(); // Limpa o campo

    // Inserção Otimista (Mostra na hora antes de salvar no banco)
    setState(() {
      _posts.insert(0, {
        'id': 'temp_${DateTime.now()}',
        'user_id': _myUserId,
        'username': 'Você',
        'photo_url': null, // TEXTO NÃO TEM FOTO
        'caption': text,
        'created_at': DateTime.now().toIso8601String(),
        'my_vote': 'owner',
      });
    });

    try {
      final result = await getIt<ArenaRepository>()
          .sendChatMessage(widget.arenaId, text);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
    } catch (e) {
      print("Erro envio texto: $e");
    }
  }
  // --------------------------

  Future<void> _uploadPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final fileBytes = await image.readAsBytes();
      final fileExt = path.extension(image.path);
      // Em arenas "Honra" (validation_type == 'manual'), foto no chat é só chat —
      // não conta como check-in nem vai para votação do tribunal.
      final bool isHonorMode = _validationType == 'manual';

      final postResult = await getIt<ArenaRepository>().postPhotoProof(
        arenaId: widget.arenaId,
        bytes: fileBytes,
        fileExt: fileExt,
        caption: _textController.text,
        isHonorMode: isHonorMode,
      );
      final postFailure = postResult.failureOrNull;
      if (postFailure != null) throw Exception(postFailure.message);

      _textController.clear();
      await _fetchFeed();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- VOTAÇÃO ---
  Future<void> _castVote(int index, String postId, bool isValid) async {
    setState(() {
      _posts[index]['my_vote'] = isValid ? 'valid' : 'fake';
      if (isValid) _posts[index]['votes_valid'] = (_posts[index]['votes_valid'] ?? 0) + 1;
      else _posts[index]['votes_fake'] = (_posts[index]['votes_fake'] ?? 0) + 1;
    });

    try {
      final result =
          await getIt<ArenaRepository>().vote(postId, isValid: isValid);
      if (result.isFailure) return;
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("CHAT", style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // LISTA DE MENSAGENS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: gold))
                : _posts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              reverse: true, // Chat começa de baixo
              padding: const EdgeInsets.only(bottom: 16, top: 16),
              itemCount: _posts.length,
              itemBuilder: (ctx, i) {
                return _FeedItem(
                  post: _posts[i],
                  isMe: _posts[i]['user_id'] == _myUserId,
                  onVote: (valid) => _castVote(i, _posts[i]['id'], valid),
                );
              },
            ),
          ),

          // BARRA DE INPUT
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF121212),
      child: SafeArea(
        child: Row(
          children: [
            // Botão Câmera
            IconButton(
              icon: const Icon(Icons.camera_alt, color: gold),
              onPressed: _uploadPhoto,
            ),
            const SizedBox(width: 8),

            // Campo de Texto
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                cursorColor: gold,
                decoration: InputDecoration(
                  hintText: "Mensagem ou legenda...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: gold, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: gold, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: gold, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 8),

            // Botão Enviar
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text("Sem mensagens ainda.", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// --- ITEM DO CHAT / FEED ---
class _FeedItem extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isMe;
  final Function(bool) onVote;

  const _FeedItem({required this.post, required this.isMe, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = post['photo_url'] != null;
    final bool isCheckin = hasPhoto && post['status'] != 'chat';

    if (hasPhoto) {
      return _buildPhotoCard(showVoting: isCheckin);
    }

    return _buildTextBubble();
  }

  Widget _buildTextBubble() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFD4AF37).withOpacity(0.2) : const Color(0xFF222222),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) Text(post['username'], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(post['caption'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({required bool showVoting}) {
    final String? myVote = post['my_vote'];
    final bool hasVoted = myVote != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      color: const Color(0xFF101010),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: post['avatar'] != null ? NetworkImage(post['avatar']) : null, radius: 16, child: post['avatar'] == null ? const Icon(Icons.person, size: 16) : null),
                const SizedBox(width: 8),
                Text(post['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (showVoting && hasVoted && myVote != 'owner')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: myVote == 'valid' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(myVote == 'valid' ? "APROVADO" : "REJEITADO", style: TextStyle(color: myVote == 'valid' ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),

          Image.network(post['photo_url'], height: 300, width: double.infinity, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post['caption'] != null) Text(post['caption'], style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),

                if (!showVoting)
                  const SizedBox.shrink()
                else if (!hasVoted)
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => onVote(false), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)), child: const Text("FAKE", style: TextStyle(color: Colors.redAccent)))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () => onVote(true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)), child: const Text("VÁLIDO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
                    ],
                  )
                else
                  Row(children: [
                    const Icon(Icons.check, color: Colors.green, size: 16), const SizedBox(width: 4), Text("${post['votes_valid']} ", style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    const Icon(Icons.close, color: Colors.red, size: 16), const SizedBox(width: 4), Text("${post['votes_fake']} ", style: const TextStyle(color: Colors.white)),
                  ]),
              ],
            ),
          )
        ],
      ),
    );
  }
}