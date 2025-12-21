import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:another_flushbar/flushbar.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_bar.dart';
import 'create_post_page.dart';
import 'chat_list_page.dart';
import 'search_page.dart';
import 'reels_page.dart';
import 'profile_page.dart';
import '../models/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeFeed(),
    const SearchPage(),
    const ReelsPage(),
    const NotificationsPage(), // New Page
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          const BottomNavigationBarItem(icon: Icon(Icons.video_collection_outlined), label: 'Reels'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.favorite_border),
                Consumer<NotificationProvider>(
                  builder: (context, notif, _) {
                    if (notif.unreadCount > 0) {
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            label: 'Activity',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  Timer? _chatTimer;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
      context.read<ChatProvider>().fetchChats();
      context.read<NotificationProvider>().fetchNotifications();
      context.read<NotificationProvider>().setupFCM();
    });
    // Poll for chats every 10 seconds for badges
    _chatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) context.read<ChatProvider>().fetchChats();
    });
    // Poll for notifications every 15 seconds for Flushbar (Web)
    _notifTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) _checkNotifications();
    });
  }

  void _checkNotifications() async {
    final notifProvider = context.read<NotificationProvider>();
    await notifProvider.fetchNotifications(silent: true);
    
    if (kIsWeb && mounted) {
      for (var n in notifProvider.notifications) {
        if (!n.isRead && notifProvider.isNew(n.id)) {
          _showWebNotification(n);
        }
      }
    }
  }

  void _showWebNotification(NotificationModel notification) {
    Flushbar(
      title: notification.title,
      message: notification.body,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.black87,
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(
        notification.type == 'like' ? Icons.favorite : 
        notification.type == 'comment' ? Icons.comment : 
        notification.type == 'follow' ? Icons.person_add : 
        Icons.notifications,
        color: Colors.white,
      ),
      onTap: (f) {
        context.read<NotificationProvider>().markAsRead(notification.id);
        f.dismiss();
      },
    ).show(context);
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _notifTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chattr',
          style: TextStyle(
            fontFamily: 'InstagramSans',
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage())),
              ),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  if (chatProvider.totalUnreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${chatProvider.totalUnreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PostProvider>().fetchPosts(),
        child: Consumer<PostProvider>(
          builder: (context, postProvider, _) {
            if (postProvider.isLoading && postProvider.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              itemCount: postProvider.posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const StoriesBar();
                }
                final post = postProvider.posts[index - 1];
                return PostCard(post: post);
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activity")),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          if (notifProvider.isLoading && notifProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notifProvider.notifications.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }
          return ListView.builder(
            itemCount: notifProvider.notifications.length,
            itemBuilder: (context, index) {
              final n = notifProvider.notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.isRead ? Colors.grey[200] : Colors.blue[100],
                  child: Icon(
                    n.type == 'like' ? Icons.favorite : 
                    n.type == 'comment' ? Icons.comment : 
                    n.type == 'follow' ? Icons.person_add : 
                    Icons.notifications,
                    color: n.isRead ? Colors.grey : Colors.blue,
                  ),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(n.body),
                trailing: !n.isRead ? const Icon(Icons.circle, size: 10, color: Colors.blue) : null,
                onTap: () => notifProvider.markAsRead(n.id),
              );
            },
          );
        },
      ),
    );
  }
}
