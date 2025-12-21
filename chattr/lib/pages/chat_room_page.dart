import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

import '../services/api_service.dart';
import 'profile_page.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class ChatRoomPage extends StatefulWidget {
  final Chat chat;

  const ChatRoomPage({super.key, required this.chat});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _messageController = TextEditingController();
  Timer? _timer;

  // Recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isSecret = false;
  int _expiresIn = 5; // Default 5 mins

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
    _audioRecorder.dispose();
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
        isSecret: _isSecret,
        expiresIn: _isSecret ? _expiresIn : null,
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

  void _pickGif() async {
    GiphyGif? gif = await GiphyGet.getGif(
      context: context,
      apiKey: "7R0B1n8lqGvVIBwA6jO6pG7S4oGvQk0e", // Example key, should be in config
      lang: GiphyLanguage.english,
    );

    if (gif != null && gif.images?.fixedHeight?.url != null) {
      context.read<ChatProvider>().sendMessage(
        widget.chat.id,
        "GIF",
        type: 'gif',
        gifUrl: gif.images!.fixedHeight!.url,
        isSecret: _isSecret,
        expiresIn: _isSecret ? _expiresIn : null,
      );
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      context.read<ChatProvider>().sendMediaMessage(widget.chat.id, image, 'image', 
        isSecret: _isSecret, expiresIn: _isSecret ? _expiresIn : null);
    }
  }

  void _pickVideo() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      context.read<ChatProvider>().sendMediaMessage(widget.chat.id, video, 'video',
        isSecret: _isSecret, expiresIn: _isSecret ? _expiresIn : null);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });
        _sendVoiceMessage();
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
        
        setState(() {
          _isRecording = true;
          _recordingPath = null;
        });
      }
    }
  }

  void _sendVoiceMessage() {
    if (_recordingPath != null) {
      final file = XFile(_recordingPath!);
      context.read<ChatProvider>().sendMediaMessage(widget.chat.id, file, 'voice',
        isSecret: _isSecret, expiresIn: _isSecret ? _expiresIn : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final otherUser = widget.chat.user1Id == currentUserId ? widget.chat.user2 : widget.chat.user1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: GestureDetector(
          onTap: () {
            if (otherUser != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: otherUser.id)));
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (otherUser?.avatar != null && otherUser!.avatar!.isNotEmpty)
                    ? NetworkImage("${ApiService.baseUrl}${otherUser.avatar}")
                    : null,
                child: (otherUser?.avatar == null || otherUser!.avatar!.isEmpty)
                    ? Text(otherUser?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser?.username ?? "Chat",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text('Active now', style: TextStyle(color: Colors.green, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[chatProvider.messages.length - 1 - index];
                    final isMe = message.senderId == currentUserId;
                    
                    return GestureDetector(
                      onLongPress: isMe ? () => _onMessageLongPress(message) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xff3797f0) : Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                                  bottomRight: Radius.circular(isMe ? 5 : 20),
                                ),
                              ),
                              child: _buildMessageContent(message, isMe),
                            ),
                            if (message.isSecret)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 10, color: Colors.grey),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Secret • ${message.expiresAt != null ? message.expiresAt!.difference(DateTime.now()).inMinutes : "?"}m left',
                                      style: const TextStyle(color: Colors.grey, fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (message.isEdited)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Edited', style: TextStyle(color: Colors.grey[400], fontSize: 9, fontStyle: FontStyle.italic)),
                              ),
                          ],
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
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 14, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Editing...', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _editingMessageId = null;
                      _messageController.clear();
                    }),
                    child: const Icon(Icons.close, size: 14, color: Colors.blue),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: _isRecording ? 'Recording...' : 'Message...',
                        enabled: !_isRecording,
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.gif_box_outlined, color: Colors.blue),
                          onPressed: _isRecording ? null : _pickGif,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined, color: Colors.blue),
                    onPressed: _isRecording ? null : _pickVideo,
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Colors.blue),
                    onPressed: _isRecording ? null : _pickImage,
                  ),
                  TextButton(
                    onPressed: _isRecording ? null : _send,
                    child: Text(
                      _editingMessageId != null ? 'Done' : 'Send',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    if (message.type == 'gif' && message.gifUrl != null) {
       return ClipRRect(
         borderRadius: BorderRadius.circular(8),
         child: Image.network(
           message.gifUrl!,
           loadingBuilder: (context, child, loadingProgress) {
             if (loadingProgress == null) return child;
             return const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
           },
         ),
       );
    }
    
    if (message.type == 'image' && message.mediaPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: "${ApiService.baseUrl}${message.mediaPath}",
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    }

    if (message.type == 'video' && message.mediaPath != null) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.videocam, size: 50, color: Colors.grey),
              const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
              // In reality we'd show a thumbnail or real player but for simplicity:
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: () {}), // Open full screen player
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (message.type == 'voice' && message.mediaPath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill, color: isMe ? Colors.white : Colors.blue, size: 30),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 2,
            color: isMe ? Colors.white54 : Colors.grey[300],
          ),
          const SizedBox(width: 8),
          Text(
            "Voice",
            style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 12),
          ),
        ],
      );
    }
    
    // Fallback/Text
    return Text(
      message.message,
      style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 15),
    );
  }
}
