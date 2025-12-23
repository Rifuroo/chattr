import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';
import '../providers/chat_provider.dart';
import 'chat_room_page.dart';
import 'settings_page.dart';
import 'followers_page.dart';
import 'edit_profile_page.dart';
import 'profile_qr_page.dart';
import 'privacy_settings_page.dart';
import 'follow_requests_page.dart';
import 'tells_page.dart';
import 'shared_stories_page.dart';
import 'quests_page.dart';
import 'roulette_page.dart';
import '../providers/privacy_provider.dart';
import '../providers/highlight_provider.dart';
import '../providers/memory_lane_provider.dart';
import '../providers/memory_lane_provider.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

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
        context.read<HighlightProvider>().fetchUserHighlights(targetId);
        if (widget.userId == null || widget.userId == context.read<AuthProvider>().user?.id) {
          context.read<PostProvider>().fetchSavedPosts();
          context.read<MemoryLaneProvider>().fetchMemoryLane();
        }
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
        final theme = _getThemeData(user.profileTheme ?? 'default');
        final textColor = _getTextColor(user.profileTheme ?? 'default');

        return DefaultTabController(
          length: isOwnProfile ? 2 : 1,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: textColor),
              title: Text(user.username, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              actions: [
                if (isOwnProfile) ...[
                  IconButton(
                    icon: const Icon(Icons.collections_bookmark_outlined), // Shared Albums
                    tooltip: "Shared Albums",
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharedStoriesPage())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowRequestsPage())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.question_answer_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TellsPage())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileQrPage(user: user)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.stars_outlined, color: Colors.orange), // Quests
                    tooltip: "Daily Quests",
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsPage())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.purple), // Roulette
                    tooltip: "Chat Roulette",
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoulettePage())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsPage())),
                  ),
                ],
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme['colors'],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: kToolbarHeight + 20),
                        _buildProfileHeader(user, isOwnProfile, textColor),
                        _buildBio(user, textColor),
                        if (isOwnProfile) _buildMemoryLane(),
                        _buildHighlightsBar(isOwnProfile),
                        if (isOwnProfile)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: user))),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(color: textColor.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ),
                        if (!isOwnProfile) ...[
                          _buildActionButtons(user, theme),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextButton.icon(
                              onPressed: () => _showSendTellDialog(context, user.id),
                              icon: Icon(Icons.question_answer, size: 16, color: textColor.withValues(alpha: 0.8)),
                              label: Text('Send Anonymous Tell', style: TextStyle(color: textColor.withValues(alpha: 0.8))),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        indicatorColor: textColor,
                        labelColor: textColor,
                        unselectedLabelColor: textColor.withValues(alpha: 0.4),
                        tabs: [
                          const Tab(icon: Icon(Icons.grid_on)),
                          if (isOwnProfile) const Tab(icon: Icon(Icons.bookmark_border)),
                        ],
                      ),
                      theme['colors'][1], // Bottom color of gradient for sticky header background
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildPostGrid(user, isSaved: false, textColor: textColor),
                    if (isOwnProfile) _buildPostGrid(user, isSaved: true, textColor: textColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(dynamic user, bool isOwnProfile, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: textColor.withValues(alpha: 0.1),
            backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                ? CachedNetworkImageProvider("${ApiService.baseUrl}${user.avatar}")
                : null,
            child: (user.avatar == null || user.avatar!.isEmpty) 
                ? Text(user.username[0].toUpperCase(), style: TextStyle(fontSize: 24, color: textColor)) 
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'Posts', count: '${user.postsCount}', textColor: textColor),
                _StatItem(label: 'Followers', count: '${user.followersCount}', textColor: textColor),
                _StatItem(label: 'Following', count: '${user.followingCount}', textColor: textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(dynamic user, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              if (user.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Colors.blue, size: 14),
              ],
              if (user.moodEmoji != null && user.moodEmoji!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.moodEmoji!, style: const TextStyle(fontSize: 12)),
                      if (user.moodText != null && user.moodText!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          user.moodText!,
                          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (user.bio != null && user.bio!.isNotEmpty) 
            Text(user.bio!, style: TextStyle(color: textColor.withValues(alpha: 0.8))),
          if (user.spotifyTrackID != null && user.spotifyTrackID!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, size: 12, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  const Text(
                    "Theme Song",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic user, Map<String, dynamic> theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.read<UserProvider>().followUser(user.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: user.isFollowing ? Colors.grey[200] : Colors.blue,
                foregroundColor: user.isFollowing ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(user.isFollowing ? 'Following' : 'Follow'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final chat = await context.read<ChatProvider>().startChat(user.id);
                if (chat != null && mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(chat: chat)));
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _getTextColor(user.profileTheme),
                side: BorderSide(color: _getTextColor(user.profileTheme).withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Message'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(dynamic user, {required bool isSaved, required Color textColor}) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        final posts = isSaved ? postProvider.savedPosts : postProvider.posts.where((p) => p.userId == user.id).toList();

        if (posts.isEmpty) {
          return Center(child: Text(isSaved ? "No saved posts" : "No posts yet", style: TextStyle(color: textColor.withValues(alpha: 0.5))));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                // Navigate to post detail
              },
              child: CachedNetworkImage(
                imageUrl: "${ApiService.baseUrl}${post.imagePath}",
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: textColor.withValues(alpha: 0.1)),
                errorWidget: (context, url, error) => Container(color: textColor.withValues(alpha: 0.1), child: Icon(Icons.error, color: textColor.withValues(alpha: 0.3))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemoryLane() {
    return Consumer<MemoryLaneProvider>(
      builder: (context, memoryProvider, _) {
        if (memoryProvider.memoryPosts.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    "Memory Lane",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: memoryProvider.memoryPosts.length,
                itemBuilder: (context, index) {
                  final post = memoryProvider.memoryPosts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage("${ApiService.baseUrl}${post.imagePath}"),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${post.createdAt.year}",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _getThemeData(String themeId) {
    switch (themeId) {
      case 'midnight':
        return {'id': 'midnight', 'colors': [const Color(0xFF1A1A2E), const Color(0xFF16213E)]};
      case 'sunset':
        return {'id': 'sunset', 'colors': [const Color(0xFFFF512F), const Color(0xFFDD2476)]};
      case 'ocean':
        return {'id': 'ocean', 'colors': [const Color(0xFF2193B0), const Color(0xFF6DD5ED)]};
      case 'emerald':
        return {'id': 'emerald', 'colors': [const Color(0xFF00B09B), const Color(0xFF96C93D)]};
      default:
        return {'id': 'default', 'colors': [Colors.white, Colors.white]};
    }
  }

  Color _getTextColor(String themeId) {
    if (themeId == 'default') return Colors.black;
    return Colors.white;
  }

  Widget _buildHighlightsBar(bool isOwnProfile) {
    return Consumer<HighlightProvider>(
      builder: (context, highlightProvider, _) {
        if (highlightProvider.userHighlights.isEmpty && !isOwnProfile) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: highlightProvider.userHighlights.length + (isOwnProfile ? 1 : 0),
              itemBuilder: (context, index) {
                if (isOwnProfile && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to create highlight page
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: const Icon(Icons.add, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text('New', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final highlight = highlightProvider.userHighlights[isOwnProfile ? index - 1 : index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to highlight detail
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                            image: highlight.coverImage != null
                                ? DecorationImage(
                                    image: NetworkImage("${ApiService.baseUrl}${highlight.coverImage}"),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: highlight.coverImage == null
                              ? const Icon(Icons.photo_library, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: Text(
                            highlight.title,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSendTellDialog(BuildContext context, int userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Anonymous Tell'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ask anything...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await context.read<PrivacyProvider>().sendTell(userId, controller.text);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tell sent anonymously!')));
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  final Color textColor;

  const _StatItem({required this.label, required this.count, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        Text(label, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
