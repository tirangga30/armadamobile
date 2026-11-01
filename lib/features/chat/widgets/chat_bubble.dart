import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatusIcon() {
    if (message.isRead) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Color(0xFF38BDF8), // Cyan / light blue for read
      );
    } else if (message.isDelivered) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Colors.white70,
      );
    } else {
      return const Icon(
        Icons.check_rounded,
        size: 15,
        color: Colors.white70,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.isOutgoing;
    final text = message.plaintextBody ?? message.ciphertextBlob;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutgoing ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
            bottomRight: Radius.circular(isOutgoing ? 4 : 16),
          ),
          border: isOutgoing
              ? null
              : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isOutgoing ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.sentAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isOutgoing ? Colors.white70 : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isOutgoing) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
