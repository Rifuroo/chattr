class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? bio;
  final String? avatar;
  final bool isPrivate;
  final String? fcmToken;
  final DateTime? createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio,
    this.avatar,
    required this.isPrivate,
    this.fcmToken,
    this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
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
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
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
    'fcm_token': fcmToken,
    'created_at': createdAt?.toIso8601String(),
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count': postsCount,
  };
}

class Post {
  final int id;
  final int userId;
  final User user;
  final String content;
  final String imagePath;
  final DateTime createdAt;
  final List<Like> likes;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.userId,
    required this.user,
    required this.content,
    required this.imagePath,
    required this.createdAt,
    required this.likes,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      content: json['content'] ?? '',
      imagePath: json['image_path'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      likes: (json['likes'] as List?)?.map((i) => Like.fromJson(i)).toList() ?? [],
      comments: (json['comments'] as List?)?.map((i) => Comment.fromJson(i)).toList() ?? [],
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

  Story({
    required this.id,
    required this.userId,
    required this.user,
    required this.mediaPath,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      mediaPath: json['media_path'] ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
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
  final DateTime updatedAt;
  final int unreadCount;

  Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.user1,
    this.user2,
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

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.isEdited,
    required this.createdAt,
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
