import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../services/api_service.dart';
import 'audio_story_recorder.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoryProvider>().fetchStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, storyProvider, _) {
        if (storyProvider.isLoading && storyProvider.stories.isEmpty) {
          return const SizedBox(height: 100);
        }

        final currentUserId = context.read<AuthProvider>().user?.id;
        final latestStories = <int, Story>{}; // Show only latest story per user
        
        for (var story in storyProvider.stories) {
          if (!latestStories.containsKey(story.userId) || story.createdAt.isAfter(latestStories[story.userId]!.createdAt)) {
            latestStories[story.userId] = story;
          }
        }

        final myStory = storyProvider.stories.where((s) => s.userId == currentUserId).toList();
        final otherStories = latestStories.values.where((s) => s.userId != currentUserId).toList();

        return Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: otherStories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    _buildAddStoryButton(myStory.isNotEmpty ? myStory.first : null),
                    _buildMomentButton(),
                  ],
                );
              }
              final story = otherStories[index - 1];
              return _buildStoryItem(story);
            },
          ),
        );
      },
    );
  }

  Widget _buildAddStoryButton(Story? myStory) {
    final currentUser = context.read<AuthProvider>().user;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (myStory != null) {
                    _showStoryViewer(myStory);
                  } else {
                    _pickAndUploadStory();
                  }
                },
                child: Container(
                  padding: myStory != null ? const EdgeInsets.all(3) : EdgeInsets.zero,
                  decoration: myStory != null ? const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ) : null,
                  child: Container(
                    padding: myStory != null ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: myStory != null ? const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ) : null,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (currentUser?.avatar != null && currentUser!.avatar!.isNotEmpty)
                          ? NetworkImage("${ApiService.baseUrl}${currentUser.avatar}")
                          : null,
                      child: (currentUser?.avatar == null || currentUser!.avatar!.isEmpty)
                          ? Text(currentUser?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 24))
                          : null,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadStory,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Your Story', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMomentButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AudioStoryRecorder(
                  onStoryCreated: () {
                    Navigator.pop(context);
                    context.read<StoryProvider>().fetchStories();
                  },
                ),
              );
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: const Icon(Icons.mic, color: Colors.blue, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Moment', style: TextStyle(fontSize: 12, color: Colors.blue)),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadStory() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final success = await context.read<StoryProvider>().createStory(image);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story uploaded!')),
        );
      }
    }
  }

  Widget _buildStoryItem(Story story) {
    return GestureDetector(
      onTap: () => _showStoryViewer(story),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (story.user.avatar != null && story.user.avatar!.isNotEmpty)
                      ? NetworkImage("${ApiService.baseUrl}${story.user.avatar}")
                      : null,
                  child: (story.user.avatar == null || story.user.avatar!.isEmpty)
                      ? Text(story.user.username[0].toUpperCase())
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.user.username,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(Story story) {
    // Record view if not own story
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (currentUserId != story.userId) {
      context.read<StoryProvider>().viewStory(story.id);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: story.isAudio 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white, size: 80),
                      const SizedBox(height: 20),
                      const Text(
                        "Chattr Moment",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Voice from ${story.user.username}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                : story.mediaPath.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: "${ApiService.baseUrl}${story.mediaPath.startsWith('/') ? '' : '/'}${story.mediaPath}",
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: (story.user.avatar != null && story.user.avatar!.isNotEmpty)
                        ? NetworkImage("${ApiService.baseUrl}${story.user.avatar}")
                        : null,
                    child: (story.user.avatar == null || story.user.avatar!.isEmpty)
                        ? Text(story.user.username[0].toUpperCase(), style: const TextStyle(fontSize: 10))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    story.user.username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
