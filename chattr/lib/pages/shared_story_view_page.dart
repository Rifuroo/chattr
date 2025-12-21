import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/story_provider.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharedStoryViewPage extends StatefulWidget {
  final int storyId;
  const SharedStoryViewPage({super.key, required this.storyId});

  @override
  State<SharedStoryViewPage> createState() => _SharedStoryViewPageState();
}

class _SharedStoryViewPageState extends State<SharedStoryViewPage> {
  @override
  void initState() {
    super.initState();
    // In a real app, you might fetch specific story details too
  }

  Future<void> _addMedia() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final success = await context.read<StoryProvider>().addSharedStoryMedia(widget.storyId, image);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Media added!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared Album"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _addMedia,
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          final story = provider.sharedStories.firstWhere((s) => s.id == widget.storyId);
          
          return Column(
            children: [
              if (story.description != null && story.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(story.description!, style: TextStyle(color: Colors.grey[600])),
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: story.media.length,
                  itemBuilder: (context, index) {
                    final media = story.media[index];
                    return GestureDetector(
                      onTap: () => _viewFullScreen(story.media, index),
                      child: CachedNetworkImage(
                        imageUrl: "${ApiService.baseUrl}${media.path}",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewFullScreen(List<SharedStoryMedia> mediaList, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              return Center(
                child: CachedNetworkImage(
                  imageUrl: "${ApiService.baseUrl}${mediaList[index].path}",
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
