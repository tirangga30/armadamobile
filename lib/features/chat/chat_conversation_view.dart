import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/theme.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/e2ee_crypto_service.dart';
import '../../core/services/socket_realtime_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/armada_api_service.dart';
import '../../providers/auth_provider.dart';
import 'widgets/chat_bubble.dart';

class ChatConversationView extends StatefulWidget {
  final ConversationModel conversation;
  final List<ChatMessageModel>? initialMessages;
  final ArmadaApiService? apiService;
  final SocketRealtimeService? socketService;

  const ChatConversationView({
    super.key,
    required this.conversation,
    this.initialMessages,
    this.apiService,
    this.socketService,
  });

  @override
  State<ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<ChatConversationView> {
  static const String _defaultMasterKey = 'armada_e2ee_shared_master_key_2026!';

  ArmadaApiService? _apiService;
  SocketRealtimeService? _socketService;
  String? _currentUserId;
  bool _initialized = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription? _chatSub;
  StreamSubscription? _ackSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.apiService != null) {
        _apiService = widget.apiService;
      } else {
        try {
          _apiService = context.read<ArmadaApiService>();
        } catch (_) {
          _apiService = ArmadaApiService(
            client: DioClient(storageService: SecureStorageService()),
          );
        }
      }

      if (widget.socketService != null) {
        _socketService = widget.socketService;
      } else {
        try {
          _socketService = context.read<SocketRealtimeService>();
        } catch (_) {}
      }

      try {
        _currentUserId = context.read<AuthProvider>().user?.id;
      } catch (_) {}

      _initRealtime();

      if (widget.initialMessages != null) {
        _messages = List.from(widget.initialMessages!);
        _isLoading = false;
      } else {
        _loadMessages();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _socketService = widget.socketService;
  }

  void _initRealtime() {
    final socket = _socketService ?? widget.socketService;
    if (socket != null) {
      socket.joinRoom('conversation:${widget.conversation.id}');
      _chatSub = socket.chatMessageStream.listen((msg) {
        if (msg.conversationId == widget.conversation.id) {
          _handleIncomingMessage(msg);
        }
      });
      _ackSub = socket.chatMessageAckStream.listen((ack) {
        final msgId = ack['messageId']?.toString();
        if (msgId != null && mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(isDelivered: true);
            }
          });
        }
      });
    }
  }

  void _handleIncomingMessage(ChatMessageModel msg) {
    final exists = _messages.any((m) =>
        m.id == msg.id || (m.ciphertextBlob.isNotEmpty && m.ciphertextBlob == msg.ciphertextBlob));
    if (exists) return;

    String? decrypted = msg.plaintextBody;
    if (decrypted == null && msg.ciphertextBlob.isNotEmpty) {
      final iv = msg.headerJson['iv'] as String? ?? '';
      try {
        decrypted = E2eeCryptoService.decrypt(
          msg.ciphertextBlob,
          _defaultMasterKey,
          iv,
        );
      } catch (_) {
        decrypted = '[Pesan terenkripsi]';
      }
    }

    final isSelf = _currentUserId != null && msg.senderUserId == _currentUserId;
    final fullMsg = msg.copyWith(
      plaintextBody: decrypted,
      isOutgoing: isSelf,
      isDelivered: true,
    );

    if (mounted) {
      setState(() {
        _messages.add(fullMsg);
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final api = _apiService ??
          widget.apiService ??
          ArmadaApiService(client: DioClient(storageService: SecureStorageService()));
      final raw = await api.getMessages(widget.conversation.id);
      final chronological = raw.reversed.toList();
      final decryptedList = chronological.map((m) {
        final isSelf = _currentUserId != null && m.senderUserId == _currentUserId;
        if (m.plaintextBody != null) return m.copyWith(isOutgoing: isSelf);
        final iv = m.headerJson['iv'] as String? ?? '';
        try {
          final text = E2eeCryptoService.decrypt(
            m.ciphertextBlob,
            _defaultMasterKey,
            iv,
          );
          return m.copyWith(plaintextBody: text, isOutgoing: isSelf);
        } catch (_) {
          return m.copyWith(plaintextBody: '[Pesan terenkripsi]', isOutgoing: isSelf);
        }
      }).toList();

      if (mounted) {
        setState(() {
          _messages = decryptedList;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      final encrypted = E2eeCryptoService.encrypt(text, _defaultMasterKey);
      final idempotencyKey = const Uuid().v4();

      String recipientDevId = const Uuid().v4();
      if (widget.conversation.driverId != null && widget.conversation.driverId!.length == 36) {
        recipientDevId = widget.conversation.driverId!;
      }
      final incoming = _messages.where(
          (m) => !m.isOutgoing && m.senderDeviceId != null && m.senderDeviceId!.length == 36);
      if (incoming.isNotEmpty) {
        recipientDevId = incoming.last.senderDeviceId!;
      }

      final dto = SendMessageDto(
        recipientDeviceId: recipientDevId,
        ciphertextBlob: encrypted.ciphertextBlob,
        headerJson: encrypted.headerJson,
        idempotencyKey: idempotencyKey,
      );

      final localMsg = ChatMessageModel(
        id: idempotencyKey,
        conversationId: widget.conversation.id,
        senderId: _currentUserId ?? 'self',
        senderUserId: _currentUserId,
        ciphertextBlob: encrypted.ciphertextBlob,
        headerJson: encrypted.headerJson,
        plaintextBody: text,
        isOutgoing: true,
        isDelivered: false,
        sentAt: DateTime.now(),
      );

      setState(() {
        _messages.add(localMsg);
      });
      _scrollToBottom();

      final api = _apiService ??
          widget.apiService ??
          ArmadaApiService(client: DioClient(storageService: SecureStorageService()));
      try {
        final saved = await api.sendChatMessage(widget.conversation.id, dto);
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == idempotencyKey);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                id: saved.id,
                isDelivered: true,
              );
            }
            _isSending = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim pesan: $e'),
              backgroundColor: AppTheme.statusDanger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _ackSub?.cancel();
    final socket = _socketService ?? widget.socketService;
    if (socket != null) {
      socket.leaveRoom('conversation:${widget.conversation.id}');
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.conversation.driverName ?? 'Driver Armada';
    try {
      final user = context.read<AuthProvider>().user;
      if (user?.role.toUpperCase() == 'DRIVER') {
        title = widget.conversation.ownerName ?? 'Owner Dispatcher';
      }
    } catch (_) {}

    final subtitle = widget.conversation.plateNumber != null
        ? '${widget.conversation.plateNumber} • Online'
        : 'Terenkripsi E2EE';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // E2EE Security Badge Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Text(
                    'Pesan terenkripsi ujung-ke-ujung (E2EE)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada percakapan.\nMulai obrolan aman sekarang.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, idx) {
                            return ChatBubble(message: _messages[idx]);
                          },
                        ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan terenkripsi...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                      tooltip: 'Kirim Pesan',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
