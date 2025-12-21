import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/reel_provider.dart';
import '../services/api_service.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().fetchReels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ReelProvider>(
        builder: (context, reelProvider, _) {
          if (reelProvider.isLoading && reelProvider.reels.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (reelProvider.reels.isEmpty) {
            return const Center(child: Text('No reels yet', style: TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reelProvider.reels.length,
            itemBuilder: (context, index) {
              final reel = reelProvider.reels[index];
              return _buildReelItem(reel);
            },
          );
        },
      ),
    );
  }

  Widget _buildReelItem(dynamic reel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Real implementation would use VideoPlayer. 
        // For UKK we use a nice placeholder if assets are images/video.
        Container(
          color: Colors.black,
          child: Center(
            child: Icon(Icons.video_collection, size: 100, color: Colors.white.withOpacity(0.2)),
          ),
        ),
        // Overlay info
        Positioned(
          bottom: 20,
          left: 20,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: reel.user.avatar != null
                        ? NetworkImage("${ApiService.baseUrl}${reel.user.avatar}")
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reel.user.username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reel.caption,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Right side buttons
        Positioned(
          bottom: 40,
          right: 15,
          child: Column(
            children: [
              _buildIconButton(Icons.favorite_outline, '1.2k'),
              const SizedBox(height: 20),
              _buildIconButton(Icons.chat_bubble_outline, '42'),
              const SizedBox(height: 20),
              _buildIconButton(Icons.send_outlined, ''),
              const SizedBox(height: 20),
              _buildIconButton(Icons.more_vert, ''),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
