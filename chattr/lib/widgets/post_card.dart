import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';
import '../pages/profile_page.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
                child: Text(
                  widget.post.user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz),
            ],
          ),
        ),
        // Image
        if (widget.post.imagePath.isNotEmpty)
          GestureDetector(
            onDoubleTap: () => context.read<PostProvider>().likePost(widget.post.id),
            child: CachedNetworkImage(
              imageUrl: "${ApiService.baseUrl}${widget.post.imagePath.startsWith('/') ? '' : '/'}${widget.post.imagePath}",
              placeholder: (context, url) => Container(height: 300, color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
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
              const Icon(Icons.send_outlined),
              const Spacer(),
              const Icon(Icons.bookmark_border),
            ],
          ),
        ),
        // Likes & Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.post.likes.length} likes",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  children: [
                    TextSpan(text: widget.post.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: " "),
                    TextSpan(text: widget.post.content),
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
                  builder: (context, postProvider, _) {
                    final updatedPost = postProvider.posts.firstWhere(
                      (p) => p.id == widget.post.id,
                      orElse: () => widget.post,
                    );
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: updatedPost.comments.length,
                      itemBuilder: (context, index) {
                        if (index >= updatedPost.comments.length) return const SizedBox.shrink();
                        final comment = updatedPost.comments[index];
                        return _buildCommentItem(comment, postProvider, setModalState);
                      },
                    );
                  },
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
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () async {
                        if (_commentController.text.isNotEmpty) {
                          final content = _commentController.text;
                          final pid = _replyingToId;
                          _commentController.clear();
                          setModalState(() {
                            _replyingToId = null;
                            _replyingToUsername = null;
                          });
                          await context.read<PostProvider>().commentPost(widget.post.id, content, parentId: pid);
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
}
