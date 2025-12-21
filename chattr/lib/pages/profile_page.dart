import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';
import '../providers/chat_provider.dart';
import 'chat_room_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final int? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetId = widget.userId ?? context.read<AuthProvider>().user?.id;
      if (targetId != null) {
        context.read<UserProvider>().fetchUserProfile(targetId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.selectedUser;
        if (userProvider.isLoading && user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (user == null) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final isOwnProfile = widget.userId == null || widget.userId == context.read<AuthProvider>().user?.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user, isOwnProfile),
                _buildBio(user),
                if (!isOwnProfile) _buildActionButtons(user),
                const Divider(),
                _buildPostGrid(user),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(dynamic user, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                ? NetworkImage("${ApiService.baseUrl}${user.avatar}")
                : null,
            child: (user.avatar == null || user.avatar!.isEmpty) ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 32)) : null,
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'Posts', count: '12'), // Placeholder counts
                _StatItem(label: 'Followers', count: '10k'),
                _StatItem(label: 'Following', count: '500'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (user.bio != null) Text(user.bio!),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic user) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final isFollowing = userProvider.isFollowing;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isFollowing) {
                      userProvider.unfollowUser(user.id);
                    } else {
                      userProvider.followUser(user.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey[200] : Colors.blue,
                    foregroundColor: isFollowing ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final chat = await context.read<ChatProvider>().startChat(user.id);
                    if (chat != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatRoomPage(chat: chat)),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostGrid(dynamic user) {
    // We would filter posts by userId here
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9, // Placeholder
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image, color: Colors.white),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
