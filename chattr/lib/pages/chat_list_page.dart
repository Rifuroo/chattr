import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().fetchChats());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatProvider.chats.isEmpty) {
            return const Center(child: Text("No messages yet.", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              final otherUser = chat.user1Id == currentUserId ? chat.user2 : chat.user1;
              
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(chat: chat))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (otherUser?.avatar != null && otherUser!.avatar!.isNotEmpty)
                            ? NetworkImage("${ApiService.baseUrl}${otherUser.avatar}")
                            : null,
                        child: (otherUser?.avatar == null || otherUser!.avatar!.isEmpty)
                            ? Text(otherUser?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 20))
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUser?.username ?? "Unknown",
                              style: TextStyle(
                                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              chat.lastMessage.isEmpty ? "Tap to chat" : chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: chat.unreadCount > 0 ? Colors.black : Colors.grey[600],
                                fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                      const SizedBox(width: 5),
                      const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
