import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../services/api_service.dart';
import 'create_shared_story_page.dart';
import 'shared_story_view_page.dart';

class SharedStoriesPage extends StatefulWidget {
  const SharedStoriesPage({super.key});

  @override
  State<SharedStoriesPage> createState() => _SharedStoriesPageState();
}

class _SharedStoriesPageState extends State<SharedStoriesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<StoryProvider>().fetchSharedStories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared Albums"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSharedStoryPage())),
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.sharedStories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.sharedStories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No shared albums yet", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSharedStoryPage())),
                    child: const Text("Create Your First Album"),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: provider.sharedStories.length,
            itemBuilder: (context, index) {
              final story = provider.sharedStories[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SharedStoryViewPage(storyId: story.id))),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: (story.coverImage != null && story.coverImage!.isNotEmpty)
                          ? NetworkImage("${ApiService.baseUrl}${story.coverImage}")
                          : const AssetImage("assets/images/placeholder.png") as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${story.members.length} members • ${story.media.length} items",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    );
  }
}
