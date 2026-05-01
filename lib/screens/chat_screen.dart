import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../services/chat_service.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/piggy_icon.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _chatStorageKeyPrefix = 'chat_messages_';
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();
  final _uuid = const Uuid();

  final List<ChatMessage> _messages = [];
  bool _isBotTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreMessages();
    });
  }

  void _addBotWelcome() {
    final user = context.read<AppProvider>().user;
    final name = user?.name.split(' ').first ?? 'friend';
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      text:
          "Hey $name! 👋 I'm Finbot, your friendly money companion! 🐷\n\nJust tell me in plain English whenever you spend money. For example:\n• \"I spent ₹500 on groceries today\"\n• \"Bought coffee for 150 rupees\"\n• \"Paid 2000 for electricity bill\"\n\nI'll automatically log it and update your savings! How's your day going? 😊",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _restoreMessages() async {
    final user = context.read<AppProvider>().user;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKeyFor(user.uid));

    if (raw == null || raw.isEmpty) {
      setState(_addBotWelcome);
      await _persistMessages();
      return;
    }

    final decoded = (jsonDecode(raw) as List<dynamic>)
        .map((item) => _chatMessageFromMap(Map<String, dynamic>.from(item)))
        .toList();

    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(decoded);
    });
    _chatService.restoreConversation(user, _messages);
    _scrollToBottom();
  }

  Future<void> _persistMessages() async {
    final user = context.read<AppProvider>().user;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKeyFor(user.uid),
      jsonEncode(_messages.map(_chatMessageToMap).toList()),
    );
  }

  String _storageKeyFor(String uid) => '$_chatStorageKeyPrefix$uid';

  Map<String, dynamic> _chatMessageToMap(ChatMessage message) => {
        'id': message.id,
        'text': message.text,
        'isUser': message.isUser,
        'timestamp': message.timestamp.toIso8601String(),
      };

  ChatMessage _chatMessageFromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] ?? _uuid.v4(),
        text: map['text'] ?? '',
        isUser: map['isUser'] ?? false,
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      );

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AppProvider>().user;
    if (user == null) return;

    _msgCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isBotTyping = true;
    });
    await _persistMessages();
    _scrollToBottom();

    final reply = await _chatService.sendMessage(
      userMessage: text,
      user: user,
    );

    // Refresh user to get updated savings
    await context.read<AppProvider>().refreshUser();

    if (!mounted) return;
    setState(() {
      _isBotTyping = false;
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    await _persistMessages();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textDark, size: 20),
        ),
        title: Row(
          children: [
            const PiggyBankIcon(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finbot',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    )),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Online',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppTheme.success,
                        )),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppTheme.primary, size: 14),
                const SizedBox(width: 4),
                Text('AI Powered',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    )),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick prompts
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip("I spent ₹500 on food 🍔"),
                  _quickChip("Paid ₹1200 for electricity 💡"),
                  _quickChip("Bought clothes for ₹2000 👗"),
                  _quickChip("What's my total spending? 📊"),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_isBotTyping && i == _messages.length) {
                  return _typingIndicator();
                }
                return _buildMessage(_messages[i]);
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _quickChip(String text) => GestureDetector(
        onTap: () {
          _msgCtrl.text = text;
          _sendMessage();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const PiggyBankIcon(size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppTheme.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _typingIndicator() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const PiggyBankIcon(size: 32),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _bouncingDot(i),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bouncingDot(int index) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500 + index * 150),
        builder: (_, v, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.3 + v * 0.7),
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _inputBar() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: GoogleFonts.nunito(fontSize: 14),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tell me what you spent...',
                    hintStyle: GoogleFonts.nunito(
                        fontSize: 14, color: AppTheme.textLight),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 4.2),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFFFF8C5A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
}
