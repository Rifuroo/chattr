import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:giphy_get/giphy_get.dart';
import '../pages/profile_page.dart';
import '../widgets/video_player_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:share_plus/share_plus.dart'; // For Share
import 'package:intl/intl.dart'; // For DateFormat
import 'spotify_player.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  String? _selectedCommentGif;

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Increment view count on first build
    Future.microtask(() => context.read<PostProvider>().viewPost(widget.post.id));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Info
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.post.user.id))),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: (widget.post.user.avatar != null && widget.post.user.avatar!.isNotEmpty)
                      ? CachedNetworkImageProvider("${ApiService.baseUrl}${widget.post.user.avatar}")
                      : null,
                  child: (widget.post.user.avatar == null || widget.post.user.avatar!.isEmpty) ? Text(widget.post.user.username[0].toUpperCase()) : null,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.post.user.id))),
                child: Row(
                  children: [
                    Text(
                      widget.post.user.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                      Text(widget.post.user.moodEmoji!, style: const TextStyle(fontSize: 12)),
                      if (widget.post.isFlash) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, size: 10, color: Colors.white),
                              SizedBox(width: 2),
                              Text("FLASH", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                ),
              ),
              const Spacer(),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isOwner = auth.user?.id == widget.post.user.id;
                  if (!isOwner) return const SizedBox.shrink();
                  
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Post'),
                            content: const Text('Are you sure you want to delete this post?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true && mounted) {
                          await context.read<PostProvider>().deletePost(widget.post.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        // Repost Branding
        if (widget.post.originalPost != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.repeat, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${widget.post.user.username} reposted",
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        
        // Media (Carousel or Single)
        _buildMedia(widget.post.originalPost ?? widget.post),

        // Spotify Track Tag
        if (widget.post.spotifyTrackID != null && widget.post.spotifyTrackID!.isNotEmpty)
          SpotifyPlayer(trackId: widget.post.spotifyTrackID!),
        
        // Poll
        if (widget.post.poll != null) _buildPoll(widget.post.poll!),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.post.likes.any((l) => l.id != 0) ? Icons.favorite : Icons.favorite_border,
                  color: widget.post.likes.any((l) => l.id != 0) ? Colors.red : Colors.black,
                ),
                onPressed: () => context.read<PostProvider>().likePost(widget.post.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => _showComments(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () => _showShareSheet(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              Consumer<PostProvider>(
                builder: (context, provider, _) {
                  final isSaved = provider.savedPosts.any((p) => p.id == widget.post.id);
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.black : Colors.black87,
                    ),
                    onPressed: () => provider.toggleSave(widget.post.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Likes & Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "${widget.post.likes.length} likes",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${widget.post.viewCount} views",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  children: [
                    TextSpan(
                      text: widget.post.user.username, 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    const TextSpan(text: " "),
                    ..._buildParsedContent(widget.post.content),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (widget.post.comments.isNotEmpty)
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: Text(
                    "View all ${widget.post.comments.length} comments",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                DateFormat.yMMMd().format(widget.post.createdAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
        List<InlineSpan> _buildParsedContent(String content) {
    final List<InlineSpan> spans = [];
    final words = content.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.startsWith('#')) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                // Should navigate to hashtag search results
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for $word...'))
                );
              },
              child: Text(
                word,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: word));
      }
      
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: " "));
      }
    }
    return spans;
  }

  Widget _buildMedia(Post post) {
    if (post.media.isEmpty) {
      // Legacy support
      if (post.imagePath == null || post.imagePath!.isEmpty) return const SizedBox.shrink();
      return _buildSingleMedia(post.imagePath!, 'image');
    }

    if (post.media.length == 1) {
      return _buildSingleMedia(post.media[0].path, post.media[0].type);
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            itemCount: post.media.length,
            itemBuilder: (context, index) {
              return _buildSingleMedia(post.media[index].path, post.media[index].type);
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: post.media.length,
            effect: const ScrollingDotsEffect(
              dotWidth: 6,
              dotHeight: 6,
              activeDotColor: Colors.blue,
              dotColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleMedia(String path, String type) {
    final fullUrl = "${ApiService.baseUrl}${path.startsWith('/') ? '' : '/'}$path";
    
    if (type == 'video') {
      return VideoPlayerWidget(url: fullUrl);
    }

    return GestureDetector(
      onDoubleTap: () => context.read<PostProvider>().likePost(widget.post.id),
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        placeholder: (context, url) => Container(height: 300, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
        errorWidget: (context, url, error) => const Icon(Icons.error),
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Share',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    context,
                    icon: Icons.repeat,
                    label: 'Repost',
                    onTap: () {
                      Navigator.pop(context);
                      _showRepostDialog(context);
                    },
                  ),
                  _buildShareOption(
                    context,
                    icon: Icons.link,
                    label: 'Copy Link',
                    onTap: () {
                      final url = "https://c-hattr.netlify.app/posts/${widget.post.id}";
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    },
                  ),
                  _buildShareOption(
                    context,
                    icon: Icons.share,
                    label: 'Share to...',
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(
                        'Check out this post on Chattr: https://c-hattr.netlify.app/posts/${widget.post.id}',
                        subject: 'Chattr Post',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showRepostDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repost with caption?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Add a thought...'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await context.read<PostProvider>().repost(widget.post.id, controller.text);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reposted successfully!')));
              }
            },
            child: const Text('Repost', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  int? _replyingToId;
  String? _replyingToUsername;

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: Consumer<PostProvider>(
                  builder: (context, provider, _) {
                    return ListView.builder(
                      itemCount: widget.post.comments.length,
                      itemBuilder: (context, index) {
                         return _buildCommentItem(widget.post.comments[index], provider, setModalState);
                      }
                    );
                  }
                ),
              ),
                  if (_selectedCommentGif != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_selectedCommentGif!, height: 100),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () => setModalState(() => _selectedCommentGif = null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_replyingToId != null)
                    Container(
                      color: Colors.grey[100],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text("Replying to @$_replyingToUsername", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setModalState(() {
                              _replyingToId = null;
                              _replyingToUsername = null;
                            }),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                      left: 10,
                      right: 10,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            autofocus: _replyingToId != null,
                            decoration: InputDecoration(
                              hintText: _replyingToId != null ? 'Reply to $_replyingToUsername...' : 'Add a comment...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                              fillColor: Colors.grey[100],
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.gif_box_outlined, color: Colors.blue),
                                onPressed: () async {
                                  GiphyGif? gif = await GiphyGet.getGif(
                                    context: context,
                                    apiKey: "7R0B1n8lqGvVIBwA6jO6pG7S4oGvQk0e",
                                    lang: GiphyLanguage.english,
                                  );
                                  if (gif != null && gif.images?.fixedHeight?.url != null) {
                                    setModalState(() => _selectedCommentGif = gif.images!.fixedHeight!.url);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () async {
                            if (_commentController.text.isNotEmpty || _selectedCommentGif != null) {
                              final content = _commentController.text;
                              final pid = _replyingToId;
                              final gifUrl = _selectedCommentGif;
                              _commentController.clear();
                              setModalState(() {
                                _replyingToId = null;
                                _replyingToUsername = null;
                                _selectedCommentGif = null;
                              });
                              await context.read<PostProvider>().commentPost(widget.post.id, content, parentId: pid, gifUrl: gifUrl);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, PostProvider provider, StateSetter setModalState, {bool isReply = false}) {
    // Check if current user liked this comment
    // (This requires having the current userId somewhere, for now let's just show count)
    final likeCount = comment.likes.length;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: isReply ? 48.0 : 16.0, right: 16.0, top: 8.0, bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: comment.user.id)));
                },
                child: CircleAvatar(
                  radius: isReply ? 12 : 16,
                  backgroundImage: (comment.user.avatar != null && comment.user.avatar!.isNotEmpty)
                      ? NetworkImage("${ApiService.baseUrl}${comment.user.avatar}")
                      : null,
                  child: (comment.user.avatar == null || comment.user.avatar!.isEmpty)
                      ? Text(comment.user.username[0].toUpperCase(), style: TextStyle(fontSize: isReply ? 8 : 12))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(text: comment.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' '),
                          TextSpan(text: comment.content),
                        ],
                      ),
                    ),
                    if (comment.gifUrl != null && comment.gifUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: comment.gifUrl!,
                            height: 120,
                            placeholder: (context, url) => SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(DateFormat.jm().format(comment.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        const SizedBox(width: 12),
                        if (likeCount > 0)
                          Text('$likeCount likes', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _replyingToId = comment.id;
                              _replyingToUsername = comment.user.username;
                            });
                          },
                          child: Text('Reply', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: Colors.grey[400],
                ),
                onPressed: () => provider.likeComment(comment.id),
              ),
            ],
          ),
        ),
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => _buildCommentItem(reply, provider, setModalState, isReply: true)).toList(),
      ],
    );
  }
  Widget _buildPoll(Poll poll) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final hasVoted = poll.votes.any((v) => v.userId == currentUserId);
    final totalVotes = poll.totalVotes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  poll.question,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (poll.isCollaborative) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("Collaborative", style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(poll.options.length, (index) {
              final option = poll.options[index];
              final optionVotes = poll.votes.where((v) => v.optionIndex == index).length;
              final percentage = totalVotes == 0 ? 0.0 : (optionVotes / totalVotes);
              final isSelected = poll.votes.any((v) => v.userId == currentUserId && v.optionIndex == index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: hasVoted ? null : () => context.read<PostProvider>().votePoll(widget.post.id, index),
                  child: Stack(
                    children: [
                      // Background Bar
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Progress Bar
                      if (hasVoted)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 45,
                          width: (MediaQuery.of(context).size.width - 64) * percentage,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      // Content
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                option.option,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue : Colors.black87,
                                ),
                              ),
                            ),
                            if (hasVoted)
                              Text(
                                '${(percentage * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.blue : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              '$totalVotes votes • ${hasVoted ? "Final Results" : "Vote to see results"}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (poll.isCollaborative && !hasVoted) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Option"),
                onPressed: () => _showAddOptionDialog(context, widget.post.id),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddOptionDialog(BuildContext context, int postId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Poll Option"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your option"),
          maxLength: 50,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await context.read<PostProvider>().addPollOption(postId, controller.text);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Option added!")));
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
