import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../library.dart';
import 'chat_logic.dart' as chat;
import 'send_overlay.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({Key? key}) : super(key: key);

  @override
  State<SendScreen> createState() => _SendScreenState();
}

// Overlays are implemented in `send_overlay.dart` to separate UI from logic.

class _SendScreenState extends State<SendScreen> {
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    final loggedUser = await getLoggedUser();
    if (loggedUser != null) {
      setState(() => _currentUser = loggedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const CupertinoPageScaffold(
        backgroundColor: Color(0xFF1C1C1E),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Messaggi',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ChatListView(
              currentUser: _currentUser!,
              onChatSelected: (user) {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder:
                        (_) => ChatViewModalPage(
                          currentUser: _currentUser!,
                          otherUser: user,
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// `showQuickOverlayMessage` moved to `send_overlay.dart` to centralize overlay helpers.

class ChatListView extends StatefulWidget {
  final String currentUser;
  final Function(String) onChatSelected;

  const ChatListView({
    Key? key,
    required this.currentUser,
    required this.onChatSelected,
  }) : super(key: key);

  @override
  _ChatListViewState createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  List<chat.Chat> _chats = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final chats = await chat.getChats(widget.currentUser);
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 7) return '${time.day}/${time.month}';
    if (diff.inDays > 0) {
      const names = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
      return names[time.weekday - 1];
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Messaggi',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Cerca',
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : ListView.builder(
                      itemCount: _chats.length,
                      itemBuilder: (ctx, i) {
                        final chatItem = _chats[i];
                        final isMoney = chatItem.lastMessage.contains(
                          'Ha inviato',
                        );
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap:
                                () => widget.onChatSelected(chatItem.otherUser),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white12,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        getProfileImage(chatItem.otherUser),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                getDisplayName(
                                                  chatItem.otherUser,
                                                ),
                                                style: const TextStyle(
                                                  color: CupertinoColors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              isMoney
                                                  ? CupertinoIcons.money_dollar
                                                  : CupertinoIcons.chat_bubble,
                                              size: 16,
                                              color: Colors.white30,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          chatItem.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTime(chatItem.lastMessageTime),
                                        style: const TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Icon(
                                        CupertinoIcons.chevron_forward,
                                        size: 18,
                                        color: Colors.white24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class ChatViewModalPage extends StatelessWidget {
  final String currentUser;
  final String otherUser;

  const ChatViewModalPage({
    Key? key,
    required this.currentUser,
    required this.otherUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: ChatViewModal(
        currentUser: currentUser,
        otherUser: otherUser,
        onBack: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class ChatViewModal extends StatefulWidget {
  final String currentUser;
  final String otherUser;
  final VoidCallback onBack;

  const ChatViewModal({
    Key? key,
    required this.currentUser,
    required this.otherUser,
    required this.onBack,
  }) : super(key: key);

  @override
  _ChatViewModalState createState() => _ChatViewModalState();
}

class _ChatViewModalState extends State<ChatViewModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _attachKey = GlobalKey();
  OverlayEntry? _attachOverlay;
  final TextEditingController _attachController = TextEditingController();
  List<chat.Message> _messages = [];
  bool _isLoading = true;
  final Set<String> _shownIncomingIds = {};
  bool _isTransferring = false;
  final Set<String> _pendingTimestamps = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _attachController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await chat.getMessages(
        widget.currentUser,
        widget.otherUser,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _maybeShowIncoming();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    final localIso = DateTime.now().toIso8601String();
    final localMsg = chat.Message(
      sender: widget.currentUser,
      receiver: widget.otherUser,
      content: content,
      timestamp: DateTime.parse(localIso),
    );
    setState(() {
      _messages.insert(0, localMsg);
      _pendingTimestamps.add(localIso);
    });
    final ok = await chat.sendMessage(
      widget.currentUser,
      widget.otherUser,
      content,
      messageId: DateTime.parse(localIso).millisecondsSinceEpoch.toString(),
      timestampIso: localIso,
    );
    if (ok) {
      setState(() => _pendingTimestamps.remove(localIso));
      await _loadMessages();
    } else {
      if (mounted) showQuickOverlayMessage(context, 'Invio non riuscito');
    }
  }

  void _maybeShowIncoming() {
    try {
      if (_messages.isEmpty) return;
      chat.Message? recent;
      for (final m in _messages) {
        if (m.content.contains('Ha inviato') &&
            m.receiver == widget.currentUser) {
          recent = m;
          break;
        }
      }
      if (recent == null) return;
      final recentId = recent.timestamp.toIso8601String();
      if (_shownIncomingIds.contains(recentId)) return; // already shown once
      final age = DateTime.now().difference(recent.timestamp).inSeconds;
      if (age > 10) return; // only show incoming if very recent

      // show incoming overlay in the root overlay so it appears on any screen
      final recentItem = recent;
      showIncomingNotification(context, recentItem.sender, recentItem.content);
      _shownIncomingIds.add(recentId);
    } catch (e) {
      // ignore
    }
  }

  void _startAttach() {
    if (_attachOverlay != null) return;
    final overlay = Overlay.of(context);
    final controller = _attachController;
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return AttachFullOverlay(
          controller: controller,
          onCancel: () {
            entry?.remove();
            _attachOverlay = null;
            controller.clear();
          },
          onSend: (value, note) async {
            final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
            if (amount <= 0) {
              showQuickOverlayMessage(context, 'Inserisci un importo valido');
              return;
            }
            // Prevent self-transfer
            if (widget.currentUser == widget.otherUser) {
              showQuickOverlayMessage(context, 'Non puoi inviarti denaro');
              return;
            }
            entry?.remove();
            _attachOverlay = null;
            setState(() => _isTransferring = true);
            final ok = await chat.transferMoney(
              widget.currentUser,
              widget.otherUser,
              amount,
            );
            if (!ok) {
              showQuickOverlayMessage(
                context,
                'Trasferimento non confermato — messaggio inviato',
              );
            }
            // don't show activity notification to sender; recipient will get incoming overlay
            var text = 'Ha inviato S${amount.toStringAsFixed(2)}';
            if (note.trim().isNotEmpty) text = '$text\n${note.trim()}';
            final nowIso = DateTime.now().toIso8601String();
            setState(
              () => _messages.insert(
                0,
                chat.Message(
                  sender: widget.currentUser,
                  receiver: widget.otherUser,
                  content: text,
                  timestamp: DateTime.parse(nowIso),
                ),
              ),
            );
            await chat.sendMessage(
              widget.currentUser,
              widget.otherUser,
              text,
              messageId:
                  DateTime.parse(nowIso).millisecondsSinceEpoch.toString(),
              timestampIso: nowIso,
            );
            await _loadMessages();
            if (mounted) setState(() => _isTransferring = false);
          },
        );
      },
    );

    _attachOverlay = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          top: MediaQuery.of(context).padding.top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.back,
                              color: Colors.white,
                            ),
                            onPressed: widget.onBack,
                          ),
                          const SizedBox(width: 12),
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  getProfileImage(widget.otherUser),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              getDisplayName(widget.otherUser),
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(child: CupertinoActivityIndicator())
                            : ListView.builder(
                              controller: _scroll_controller_safe(),
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final mapped = _messages.length - 1 - index;
                                final message = _messages[mapped];
                                final isMe =
                                    message.sender == widget.currentUser;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        isMe
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.75,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isMe
                                                  ? const Color(0xFF2E5CD1)
                                                  : const Color(0xFF23232B),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 28.0,
                                              ),
                                              child: Text(
                                                message.content,
                                                style: const TextStyle(
                                                  color: CupertinoColors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (isMe)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Icon(
                                                  _pendingTimestamps.contains(
                                                        message.timestamp
                                                            .toIso8601String(),
                                                      )
                                                      ? Icons.access_time
                                                      : Icons.check,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF23232B),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              key: _attachKey,
                              padding: const EdgeInsets.only(left: 4),
                              child:
                                  _isTransferring
                                      ? const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                      : IconButton(
                                        tooltip: 'Allega denaro',
                                        icon: const Icon(
                                          Icons.attach_money,
                                          color: Colors.white,
                                        ),
                                        onPressed: _startAttach,
                                      ),
                            ),
                            Expanded(
                              child: CupertinoTextField(
                                controller: _messageController,
                                placeholder: 'Messaggio...',
                                placeholderStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: GestureDetector(
                                onTap: _sendMessage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E5CD1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.arrow_up,
                                    color: CupertinoColors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  ScrollController _scroll_controller_safe() {
    return _scroll_controller_or_default(_scrollController);
  }

  ScrollController _scroll_controller_or_default(ScrollController? ctrl) {
    return ctrl ?? ScrollController();
  }
}

class ChatView extends StatefulWidget {
  final String currentUser;
  final String otherUser;
  final VoidCallback onBack;

  const ChatView({
    Key? key,
    required this.currentUser,
    required this.otherUser,
    required this.onBack,
  }) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<chat.Message> _messages = [];
  bool _isLoading = true;
  bool _isTransferring = false;
  final Set<String> _pendingTimestamps = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await chat.getMessages(
        widget.currentUser,
        widget.otherUser,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    final localIso = DateTime.now().toIso8601String();
    final localMsg = chat.Message(
      sender: widget.currentUser,
      receiver: widget.otherUser,
      content: content,
      timestamp: DateTime.parse(localIso),
    );
    setState(() => _messages.insert(0, localMsg));
    final ok = await chat.sendMessage(
      widget.currentUser,
      widget.otherUser,
      content,
      messageId: DateTime.parse(localIso).millisecondsSinceEpoch.toString(),
      timestampIso: localIso,
    );
    if (ok) await _loadMessages();
  }

  // Inline chat view attach uses the same full-screen overlay
  void _startAttachBubble() {
    final overlay = Overlay.of(context);
    final attachController = TextEditingController();
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder:
          (ctx) => AttachFullOverlay(
            controller: attachController,
            onCancel: () {
              entry?.remove();
              attachController.dispose();
            },
            onSend: (value, note) async {
              final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
              if (amount <= 0) {
                showQuickOverlayMessage(context, 'Inserisci un importo valido');
                return;
              }
              // Prevent self-transfer
              if (widget.currentUser == widget.otherUser) {
                showQuickOverlayMessage(context, 'Non puoi inviarti denaro');
                return;
              }
              entry?.remove();
              attachController.dispose();
              setState(() => _isTransferring = true);
              final ok = await chat.transferMoney(
                widget.currentUser,
                widget.otherUser,
                amount,
              );
              if (!ok) {
                showQuickOverlayMessage(
                  context,
                  'Trasferimento non confermato — messaggio inviato',
                );
              }
              // show a richer activity notification (profile + amount) on the sender device
              showQuickOverlayMessage(
                context,
                '',
                fromUser: widget.currentUser,
                amountText: amount.toStringAsFixed(2),
                duration: const Duration(seconds: 3),
              );
              var text = 'Ha inviato S${amount.toStringAsFixed(2)}';
              if (note.trim().isNotEmpty) text = '$text\n${note.trim()}';
              final nowIso = DateTime.now().toIso8601String();
              setState(
                () => _messages.insert(
                  0,
                  chat.Message(
                    sender: widget.currentUser,
                    receiver: widget.otherUser,
                    content: text,
                    timestamp: DateTime.parse(nowIso),
                  ),
                ),
              );
              await chat.sendMessage(
                widget.currentUser,
                widget.otherUser,
                text,
                messageId:
                    DateTime.parse(nowIso).millisecondsSinceEpoch.toString(),
                timestampIso: nowIso,
              );
              await _loadMessages();
              if (mounted) setState(() => _isTransferring = false);
            },
          ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = getProfileImage(widget.otherUser);
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(CupertinoIcons.back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(profileImage, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getDisplayName(widget.otherUser),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final mapped = _messages.length - 1 - index;
                      final message = _messages[mapped];
                      final isMe = message.sender == widget.currentUser;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment:
                              isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? const Color(0xFF2E5CD1)
                                        : const Color(0xFF23232B),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 28.0),
                                    child: Text(
                                      message.content,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isMe)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(
                                        _pendingTimestamps.contains(
                                              message.timestamp
                                                  .toIso8601String(),
                                            )
                                            ? Icons.access_time
                                            : Icons.check,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF23232B),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _isTransferring
                      ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                      : IconButton(
                        tooltip: 'Allega denaro',
                        icon: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                        ),
                        onPressed: _startAttachBubble,
                      ),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Messaggio...',
                      placeholderStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E5CD1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.arrow_up,
                          color: CupertinoColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
