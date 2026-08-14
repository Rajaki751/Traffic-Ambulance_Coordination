import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/auth_widgets.dart';

const _kWaTeal = Color(0xFF128C7E);
const _kWaBubbleMine = Color(0xFFDCF8C6);
const _kDriverGreen = Color(0xFF2F9E63);
const _kOfficerRed = Color(0xFFE23D3D);

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

  void _showParticipants(BuildContext context) {
    final text = GoogleFonts.inter();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kAuthCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Participants',
          style: text.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kAuthText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: buildParticipantRows(widget.session, text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: text.copyWith(color: kAuthMuted)),
          ),
        ],
      ),
    );
  }

  List<Widget> buildParticipantRows(ChatSessionSummary s, TextStyle text) {
    final rows = <Widget>[];
    for (final p in s.participants) {
      final isDriver = p.isDriver;
      rows.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isDriver ? _kDriverGreen : _kOfficerRed,
          child: Text(
            p.initials,
            style: text.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          p.name,
          style: text.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isDriver ? 'Driver' : 'Traffic officer',
          style: text.copyWith(
            fontSize: 12,
            color: isDriver ? _kDriverGreen : _kOfficerRed,
            fontWeight: FontWeight.w600,
          ),
        ),
      ));
    }
    if (rows.isEmpty) {
      rows.add(Text('No participants yet', style: text.copyWith(color: kAuthFaint)));
    }
    return rows;
  }

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
        title: InkWell(
          onTap: () => _showParticipants(context),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kWaTeal,
                child: Text(
                  widget.session.drivers.isEmpty
                      ? 'AMB'
                      : widget.session.drivers.first.initials,
                  style: text.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.vehicleNumber,
                    style: text.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kAuthText,
                    ),
                  ),
                  Text(
                    '${widget.session.officers.length} officer(s) · tap for details',
                    style: text.copyWith(fontSize: 11, color: kAuthMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: GlassBackdrop(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet — say hello!',
                        style: text.copyWith(fontSize: 14, color: kAuthFaint),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
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
    return Column(
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!mine) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: m.isFromDriver ? _kDriverGreen : _kOfficerRed,
                  child: Text(
                    m.initials,
                    style: text.copyWith(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  m.senderName,
                  style: text.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kAuthText,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: (m.isFromDriver ? _kDriverGreen : _kOfficerRed)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.isFromDriver ? 'Driver' : 'Officer',
                    style: text.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: m.isFromDriver ? _kDriverGreen : _kOfficerRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 310),
            decoration: BoxDecoration(
              color: mine ? _kWaBubbleMine : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(mine ? 14 : 4),
                bottomRight: Radius.circular(mine ? 4 : 14),
              ),
              border: mine ? null : Border.all(color: kAuthBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  m.message,
                  style: text.copyWith(
                    fontSize: 14,
                    color: kAuthText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timeLabel(m.createdAt),
                      style: text.copyWith(
                        fontSize: 10,
                        color: kAuthFaint,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: _kDriverGreen,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                cursorColor: _kWaTeal,
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: text.copyWith(fontSize: 14, color: kAuthFaint),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: kAuthBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: kAuthBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _kWaTeal, width: 1.4),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(chat),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _kWaTeal,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: chat.sending ? null : () => _send(chat),
                icon: chat.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}