import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchExploreFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _isSearching = value.isNotEmpty;
              });
              context.read<UserProvider>().searchUsers(value);
            },
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildExploreGrid(),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userProvider.searchResults.isEmpty) {
          return const Center(child: Text("No users found"));
        }
        return ListView.builder(
          itemCount: userProvider.searchResults.length,
          itemBuilder: (context, index) {
            final user = userProvider.searchResults[index];
            return ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: user.id))),
              leading: CircleAvatar(
                backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                  ? NetworkImage("${ApiService.baseUrl}${user.avatar}")
                  : null,
                child: (user.avatar == null || user.avatar!.isEmpty) ? Text(user.username[0].toUpperCase()) : null,
              ),
              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.name),
            );
          },
        );
      },
    );
  }

  Widget _buildExploreGrid() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        if (postProvider.isLoading && postProvider.explorePosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return RefreshIndicator(
          onRefresh: () => postProvider.fetchExploreFeed(),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: postProvider.explorePosts.length,
            itemBuilder: (context, index) {
              final post = postProvider.explorePosts[index];
              return _buildGridItem(post);
            },
          ),
        );
      },
    );
  }

  Widget _buildGridItem(Post post) {
    String? thumbPath;
    if (post.media.isNotEmpty) {
      thumbPath = post.media[0].path;
    } else if (post.imagePath != null && post.imagePath!.isNotEmpty) {
      thumbPath = post.imagePath;
    }

    if (thumbPath == null) return Container(color: Colors.grey[300]);

    return GestureDetector(
      onTap: () {
        // Navigation to a "Single Post View" or "Explore Feed view" would go here
        // For now, let's just show a snackbar or placeholder
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: "${ApiService.baseUrl}$thumbPath",
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          if (post.media.length > 1)
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(Icons.collections, color: Colors.white, size: 18),
            ),
          if (post.media.isNotEmpty && post.media[0].type == 'video')
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}
