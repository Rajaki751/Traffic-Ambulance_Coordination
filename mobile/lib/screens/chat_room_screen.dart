import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/auth_widgets.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.session});

  final ChatSessionSummary session;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().loadMessages(widget.session.emergencySessionId);
    });
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ChatProvider chat) {
    final msg = _composer.text.trim();
    if (msg.isEmpty || chat.sending) return;
    _composer.clear();
    chat.sendMessage(widget.session.emergencySessionId, msg).catchError((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String _timeLabel(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final myId = auth.user?.id;
    final messages = chat.messagesFor(widget.session.emergencySessionId);
    final text = GoogleFonts.inter();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: kAuthText,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const FrostedAppBarBackdrop(),
        shape: const Border(bottom: BorderSide(color: kAuthBorder)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.vehicleNumber,
              style: text.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kAuthText,
              ),
            ),
            Text(
              widget.session.destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.copyWith(fontSize: 11.5, color: kAuthMuted),
            ),
          ],
        ),
      ),
      body: GlassBackdrop(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text('No messages yet — say hello!'),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final mine = m.senderUserId == myId;
                        return _bubble(context, m, mine, text);
                      },
                    ),
            ),
            _composerBar(context, chat, text),
          ],
        ),
      ),
    );
  }

  Widget _bubble(
    BuildContext context,
    ChatMessageModel m,
    bool mine,
    TextStyle text,
  ) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: mine ? kAuthRed : kAuthCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: mine ? null : Border.all(color: kAuthBorder),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                m.senderName,
                style: text.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kAuthGreen,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              m.message,
              style: text.copyWith(
                fontSize: 13.5,
                color: mine ? Colors.white : kAuthText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _timeLabel(m.createdAt),
              style: text.copyWith(
                fontSize: 10,
                color: mine ? Colors.white70 : kAuthFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerBar(
    BuildContext context,
    ChatProvider chat,
    TextStyle text,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kGlassBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 4,
                style: text.copyWith(fontSize: 14, color: kAuthText),
                cursorColor: kAuthRed,
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: text.copyWith(fontSize: 14, color: kAuthFaint),
                  filled: true,
                  fillColor: kAuthCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: kAuthBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: kAuthBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: kAuthRed, width: 1.2),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(chat),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: chat.sending ? null : () => _send(chat),
              style: IconButton.styleFrom(
                backgroundColor: kAuthRed,
                disabledBackgroundColor: kAuthBorder,
                foregroundColor: Colors.white,
              ),
              icon: chat.sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}