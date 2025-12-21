import 'dart:convert';

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? bio;
  final String? avatar;
  final bool isPrivate;
  final bool isVerified;
  final String? spotifyTrackID;
  final String? fcmToken;
  final DateTime? createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String? moodEmoji;
  final String? moodText;
  final bool isGhostMode;
  final String profileTheme;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio,
    this.avatar,
    required this.isPrivate,
    this.isVerified = false,
    this.spotifyTrackID,
    this.fcmToken,
    this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.moodEmoji,
    this.moodText,
    this.isGhostMode = false,
    this.profileTheme = 'default',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      avatar: json['avatar'],
      isPrivate: json['is_private'] ?? false,
      isVerified: json['is_verified'] ?? false,
      spotifyTrackID: json['spotify_track_id'],
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      moodEmoji: json['mood_emoji'],
      moodText: json['mood_text'],
      isGhostMode: json['is_ghost_mode'] ?? false,
      profileTheme: json['profile_theme'] ?? 'default',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'bio': bio,
    'avatar': avatar,
    'is_private': isPrivate,
    'is_verified': isVerified,
    'spotify_track_id': spotifyTrackID,
    'fcm_token': fcmToken,
    'created_at': createdAt?.toIso8601String(),
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count': postsCount,
    'mood_emoji': moodEmoji,
    'mood_text': moodText,
    'is_ghost_mode': isGhostMode,
    'profile_theme': profileTheme,
  };
}

class Quest {
  final int id;
  final String title;
  final String description;
  final int points;
  final String targetAction;
  final int targetCount;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.targetAction,
    required this.targetCount,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      targetAction: json['target_action'] ?? '',
      targetCount: json['target_count'] ?? 0,
    );
  }
}

class UserQuest {
  final int id;
  final int userId;
  final int questId;
  final Quest? quest;
  final int progress;
  final bool isCompleted;

  UserQuest({
    required this.id,
    required this.userId,
    required this.questId,
    this.quest,
    required this.progress,
    required this.isCompleted,
  });

  factory UserQuest.fromJson(Map<String, dynamic> json) {
    return UserQuest(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      questId: json['quest_id'] ?? 0,
      quest: json['quest'] != null ? Quest.fromJson(json['quest']) : null,
      progress: json['progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class Post {
  final int id;
  final int userId;
  final User user;
  final String content;
  final String? imagePath;
  final DateTime createdAt;
  final List<Like> likes;
  final List<Comment> comments;
  final List<PostMedia> media;
  final Post? originalPost;
  final Poll? poll;
  final int viewCount;
  final String? spotifyTrackID;
  final bool isFlash;
  final DateTime? expiresAt;

  Post({
    required this.id,
    required this.userId,
    required this.user,
    required this.content,
    this.imagePath,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
    this.media = const [],
    this.originalPost,
    this.poll,
    this.viewCount = 0,
    this.spotifyTrackID,
    this.isFlash = false,
    this.expiresAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      content: json['content'] ?? '',
      imagePath: json['image_path'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      likes: (json['likes'] as List?)?.map((i) => Like.fromJson(i)).toList() ?? [],
      comments: (json['comments'] as List?)?.map((i) => Comment.fromJson(i)).toList() ?? [],
      media: (json['media'] as List?)?.map((i) => PostMedia.fromJson(i)).toList() ?? [],
      originalPost: json['original_post'] != null ? Post.fromJson(json['original_post']) : null,
      poll: json['poll'] != null ? Poll.fromJson(json['poll']) : null,
      viewCount: json['view_count'] ?? 0,
      spotifyTrackID: json['spotify_track_id'],
      isFlash: json['is_flash'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
    );
  }
}

class Poll {
  final int id;
  final int postId;
  final String question;
  final List<PollOption> options;
  final DateTime expiresAt;
  final List<PollVote> votes;
  final bool isCollaborative;

  Poll({
    required this.id,
    required this.postId,
    required this.question,
    required this.options,
    required this.expiresAt,
    this.votes = const [],
    this.isCollaborative = false,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] ?? 0,
      postId: json['post_id'] ?? 0,
      question: json['question'] ?? '',
      options: (json['options'] as List?)?.map((o) => PollOption.fromJson(o)).toList() ?? [],
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      votes: (json['votes'] as List?)?.map((i) => PollVote.fromJson(i)).toList() ?? [],
      isCollaborative: json['is_collaborative'] ?? false,
    );
  }

  int get totalVotes => votes.length;
}

class PollOption {
  final int id;
  final int pollId;
  final String option;
  final int createdById;
  final User? createdBy;

  PollOption({
    required this.id,
    required this.pollId,
    required this.option,
    required this.createdById,
    this.createdBy,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] ?? 0,
      pollId: json['poll_id'] ?? 0,
      option: json['option'] ?? '',
      createdById: json['created_by_id'] ?? 0,
      createdBy: json['created_by'] != null ? User.fromJson(json['created_by']) : null,
    );
  }
}

class PollVote {
  final int id;
  final int pollId;
  final int userId;
  final int optionIndex;

  PollVote({
    required this.id,
    required this.pollId,
    required this.userId,
    required this.optionIndex,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'] ?? 0,
      pollId: json['poll_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      optionIndex: json['option_index'] ?? 0,
    );
  }
}

class PostMedia {
  final int id;
  final int postId;
  final String path;
  final String type; // image, video
  final DateTime createdAt;

  PostMedia({
    required this.id,
    required this.postId,
    required this.path,
    required this.type,
    required this.createdAt,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'] ?? 0,
      postId: json['post_id'] ?? 0,
      path: json['path'] ?? '',
      type: json['type'] ?? 'image',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Reel {
  final int id;
  final int userId;
  final User user;
  final String videoPath;
  final String caption;
  final DateTime createdAt;

  Reel({
    required this.id,
    required this.userId,
    required this.user,
    required this.videoPath,
    required this.caption,
    required this.createdAt,
  });

  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      videoPath: json['video_path'] ?? '',
      caption: json['caption'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Story {
  final int id;
  final int userId;
  final User user;
  final String mediaPath;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool isAudio;

  Story({
    required this.id,
    required this.userId,
    required this.user,
    required this.mediaPath,
    required this.expiresAt,
    required this.createdAt,
    this.isAudio = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      mediaPath: json['media_path'] ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isAudio: json['is_audio'] ?? false,
    );
  }
}

class Like {
  final int id;
  final int userId;
  final int postId;

  Like({required this.id, required this.userId, required this.postId});

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      postId: json['post_id'] ?? 0,
    );
  }
}

class Comment {
  final int id;
  final int userId;
  final User user;
  final int postId;
  final int? parentId;
  final String content;
  final DateTime createdAt;
  final List<CommentLike> likes;
  final List<Comment> replies;
  final String? gifUrl;

  Comment({
    required this.id,
    required this.userId,
    required this.user,
    required this.postId,
    this.parentId,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.replies,
    this.gifUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      postId: json['post_id'] ?? 0,
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      likes: (json['likes'] as List?)?.map((i) => CommentLike.fromJson(i)).toList() ?? [],
      replies: (json['replies'] as List?)?.map((i) => Comment.fromJson(i)).toList() ?? [],
      gifUrl: json['gif_url'],
    );
  }
}

class CommentLike {
  final int id;
  final int userId;
  final int commentId;

  CommentLike({required this.id, required this.userId, required this.commentId});

  factory CommentLike.fromJson(Map<String, dynamic> json) {
    return CommentLike(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      commentId: json['comment_id'] ?? 0,
    );
  }
}

class Chat {
  final int id;
  final int user1Id;
  final int user2Id;
  final User? user1;
  final User? user2;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.user1,
    this.user2,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? 0,
      user1Id: json['user1_id'] ?? 0,
      user2Id: json['user2_id'] ?? 0,
      user1: json['User1'] != null ? User.fromJson(json['User1']) : null,
      user2: json['User2'] != null ? User.fromJson(json['User2']) : null,
      lastMessage: json['last_message'] ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String message;
  final bool isRead;
  final bool isEdited;
  final DateTime createdAt;
  final String type;
  final String? mediaPath;
  final bool isSecret;
  final DateTime? expiresAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.isEdited,
    required this.createdAt,
    this.type = 'text',
    this.mediaPath,
    this.isSecret = false,
    this.expiresAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      chatId: json['chat_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      isEdited: json['is_edited'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      type: json['type'] ?? 'text',
      mediaPath: json['media_path'],
      isSecret: json['is_secret'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
    );
  }
}

class FollowRequest {
  final int id;
  final int followerId;
  final int userId;
  final String status;
  final DateTime createdAt;
  final User? follower;

  FollowRequest({
    required this.id,
    required this.followerId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.follower,
  });

  factory FollowRequest.fromJson(Map<String, dynamic> json) {
    return FollowRequest(
      id: json['id'] ?? 0,
      followerId: json['follower_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      follower: json['follower'] != null ? User.fromJson(json['follower']) : null,
    );
  }
}

class Tell {
  final int id;
  final int userId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Tell({
    required this.id,
    required this.userId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Tell.fromJson(Map<String, dynamic> json) {
    return Tell(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      content: json['content'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SharedStory {
  final int id;
  final int creatorId;
  final User? creator;
  final String title;
  final String? description;
  final String? coverImage;
  final List<SharedStoryMember> members;
  final List<SharedStoryMedia> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedStory({
    required this.id,
    required this.creatorId,
    this.creator,
    required this.title,
    this.description,
    this.coverImage,
    required this.members,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SharedStory.fromJson(Map<String, dynamic> json) {
    return SharedStory(
      id: json['id'] ?? 0,
      creatorId: json['creator_id'] ?? 0,
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      title: json['title'] ?? '',
      description: json['description'],
      coverImage: json['cover_image'],
      members: (json['members'] as List?)?.map((i) => SharedStoryMember.fromJson(i)).toList() ?? [],
      media: (json['media'] as List?)?.map((i) => SharedStoryMedia.fromJson(i)).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SharedStoryMember {
  final int id;
  final int sharedStoryId;
  final int userId;
  final User? user;
  final String role;

  SharedStoryMember({
    required this.id,
    required this.sharedStoryId,
    required this.userId,
    this.user,
    required this.role,
  });

  factory SharedStoryMember.fromJson(Map<String, dynamic> json) {
    return SharedStoryMember(
      id: json['id'] ?? 0,
      sharedStoryId: json['shared_story_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      role: json['role'] ?? 'member',
    );
  }
}

class SharedStoryMedia {
  final int id;
  final int sharedStoryId;
  final int userId;
  final User? user;
  final String path;
  final String type;
  final DateTime createdAt;

  SharedStoryMedia({
    required this.id,
    required this.sharedStoryId,
    required this.userId,
    this.user,
    required this.path,
    required this.type,
    required this.createdAt,
  });

  factory SharedStoryMedia.fromJson(Map<String, dynamic> json) {
    return SharedStoryMedia(
      id: json['id'] ?? 0,
      sharedStoryId: json['shared_story_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      path: json['path'] ?? '',
      type: json['type'] ?? 'image',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Highlight {
  final int id;
  final int creatorId;
  final User? creator;
  final String title;
  final String? coverImage;
  final List<HighlightMember> members;
  final List<HighlightItem> items;
  final bool isShared;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.creatorId,
    this.creator,
    required this.title,
    this.coverImage,
    this.members = const [],
    this.items = const [],
    this.isShared = false,
    required this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] ?? 0,
      creatorId: json['creator_id'] ?? 0,
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      title: json['title'] ?? '',
      coverImage: json['cover_image'],
      members: (json['members'] as List?)?.map((i) => HighlightMember.fromJson(i)).toList() ?? [],
      items: (json['items'] as List?)?.map((i) => HighlightItem.fromJson(i)).toList() ?? [],
      isShared: json['is_shared'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class HighlightMember {
  final int id;
  final int highlightId;
  final int userId;
  final User? user;

  HighlightMember({
    required this.id,
    required this.highlightId,
    required this.userId,
    this.user,
  });

  factory HighlightMember.fromJson(Map<String, dynamic> json) {
    return HighlightMember(
      id: json['id'] ?? 0,
      highlightId: json['highlight_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class HighlightItem {
  final int id;
  final int highlightId;
  final int storyId;
  final Story? story;
  final DateTime createdAt;

  HighlightItem({
    required this.id,
    required this.highlightId,
    required this.storyId,
    this.story,
    required this.createdAt,
  });

  factory HighlightItem.fromJson(Map<String, dynamic> json) {
    return HighlightItem(
      id: json['id'] ?? 0,
      highlightId: json['highlight_id'] ?? 0,
      storyId: json['story_id'] ?? 0,
      story: json['story'] != null ? Story.fromJson(json['story']) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
