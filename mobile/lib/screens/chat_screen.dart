import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../widgets/auth_widgets.dart';
import 'chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatProvider>().loadSessions();
    });
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final sameDay = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    if (sameDay) return DateFormat('HH:mm').format(dt.toLocal());
    return DateFormat('MMM d').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
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
        title: Text(
          'Chat',
          style: text.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: kAuthText,
          ),
        ),
      ),
      body: GlassBackdrop(
        child: chat.loading && chat.sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : chat.sessions.isEmpty
                ? RefreshIndicator(
                    onRefresh: chat.loadSessions,
                    child: const AuthEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No conversations yet',
                      hint: 'Chat with drivers and officers for each emergency '
                          'trip will appear here.',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: chat.loadSessions,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.sessions.length,
                      itemBuilder: (_, i) {
                        final s = chat.sessions[i];
                        return _sessionCard(context, chat, s, text);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _sessionCard(
    BuildContext context,
    ChatProvider chat,
    ChatSessionSummary s,
    TextStyle text,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      shadowColor: Colors.transparent,
      color: kAuthCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kAuthBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          chat.openSession(s.emergencySessionId);
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ChatRoomScreen(session: s)))
              .then((_) {
            if (mounted) chat.loadSessions();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kAuthRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s.status == 'active'
                      ? Icons.local_shipping_rounded
                      : Icons.history_rounded,
                  color: kAuthRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.vehicleNumber,
                            style: text.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: kAuthText,
                            ),
                          ),
                        ),
                        Text(
                          _timeLabel(s.lastMessageAt),
                          style: text.copyWith(
                            fontSize: 11,
                            color: kAuthFaint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.copyWith(fontSize: 12, color: kAuthMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.lastMessage ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.copyWith(
                        fontSize: 12.5,
                        color: s.lastMessage == null ? kAuthFaint : kAuthMuted,
                        fontWeight:
                            s.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kAuthRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${s.unreadCount}',
                    style: text.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}