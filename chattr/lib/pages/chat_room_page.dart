import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

import '../services/api_service.dart';
import 'profile_page.dart';

class ChatRoomPage extends StatefulWidget {
  final Chat chat;

  const ChatRoomPage({super.key, required this.chat});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _messageController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Start polling every 3 seconds for messages
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _fetchMessages() {
    if (!mounted) return;
    try {
      context.read<ChatProvider>().fetchMessages(widget.chat.id);
      context.read<ChatProvider>().markAsRead(widget.chat.id);
    } catch (e) {
      print("Polling error caught: $e");
    }
  }

  int? _editingMessageId;

  void _onMessageLongPress(Message message) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (message.senderId != currentUserId) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              if (!mounted) return;
              setState(() {
                _editingMessageId = message.id;
                _messageController.text = message.message;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Message?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await context.read<ChatProvider>().deleteMessage(widget.chat.id, message.id);
              }
            },
          ),
        ],
      ),
    );
  }

  void _send() async {
    if (_messageController.text.isEmpty) return;
    
    bool success;
    if (_editingMessageId != null) {
      success = await context.read<ChatProvider>().editMessage(
        widget.chat.id,
        _editingMessageId!,
        _messageController.text,
      );
    } else {
      success = await context.read<ChatProvider>().sendMessage(
        widget.chat.id,
        _messageController.text,
      );
    }

    if (success) {
      _messageController.clear();
      if (!mounted) return;
      setState(() {
        _editingMessageId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final otherUser = widget.chat.user1Id == currentUserId ? widget.chat.user2 : widget.chat.user1;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (otherUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(userId: otherUser.id)),
              );
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: (otherUser?.avatar != null && otherUser!.avatar!.isNotEmpty)
                    ? NetworkImage("${ApiService.baseUrl}${otherUser.avatar}")
                    : null,
                child: (otherUser?.avatar == null || otherUser!.avatar!.isEmpty)
                    ? Text(otherUser?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 10),
              Text(otherUser?.username ?? "Chat", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  reverse: true, // Show newest messages at bottom
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    // Reverse the list locally for display
                    final message = chatProvider.messages[chatProvider.messages.length - 1 - index];
                    final isMe = message.senderId == currentUserId;
                    
                    return GestureDetector(
                      onLongPress: isMe ? () => _onMessageLongPress(message) : null,
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                              ),
                              if (message.isEdited)
                                Text(
                                  '(edited)',
                                  style: TextStyle(
                                    color: (isMe ? Colors.white : Colors.black).withOpacity(0.5),
                                    fontSize: 8,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_editingMessageId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Editing message', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingMessageId = null;
                        _messageController.clear();
                      });
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none),
                    ),
                  ),
                  TextButton(
                    onPressed: _send,
                    child: Text(
                      _editingMessageId != null ? 'Update' : 'Send',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
