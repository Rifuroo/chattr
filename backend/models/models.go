package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Name      string         `json:"name"`
	Username  string         `gorm:"type:varchar(191);uniqueIndex" json:"username"`
	Email     string         `gorm:"type:varchar(191);uniqueIndex" json:"email"`
	Password  string         `json:"-"`
	Bio       string         `json:"bio"`
	Avatar    string         `json:"avatar"`
	IsPrivate bool           `json:"is_private" gorm:"default:false"`
	FCMToken  string         `json:"fcm_token"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	FollowersCount int64 `json:"followers_count" gorm:"-"`
	FollowingCount int64 `json:"following_count" gorm:"-"`
	PostsCount     int64 `json:"posts_count" gorm:"-"`
}

type Follow struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	FollowerID  uint      `json:"follower_id"`
	FollowingID uint      `json:"following_id"`
	Follower    User      `gorm:"foreignKey:FollowerID" json:"follower"`
	Following   User      `gorm:"foreignKey:FollowingID" json:"following"`
	CreatedAt   time.Time `json:"created_at"`
}

type Post struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `json:"user_id"`
	User      User      `json:"user"`
	Content   string    `json:"content"`
	ImagePath string    `json:"image_path"`
	CreatedAt time.Time `json:"created_at"`
	Likes     []Like    `json:"likes"`
	Comments  []Comment `json:"comments"`
}

type Reel struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `json:"user_id"`
	User      User      `json:"user"`
	VideoPath string    `json:"video_path"`
	Caption   string    `json:"caption"`
	CreatedAt time.Time `json:"created_at"`
}

type Story struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `json:"user_id"`
	User      User      `json:"user"`
	MediaPath string    `json:"media_path"`
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

type Like struct {
	ID     uint `gorm:"primaryKey" json:"id"`
	UserID uint `json:"user_id"`
	PostID uint `json:"post_id"`
}

type Comment struct {
	ID        uint          `gorm:"primaryKey" json:"id"`
	UserID    uint          `json:"user_id"`
	User      User          `json:"user"`
	PostID    uint          `json:"post_id"`
	ParentID  *uint         `json:"parent_id"` // For replies
	Content   string        `json:"content"`
	CreatedAt time.Time     `json:"created_at"`
	Likes     []CommentLike `json:"likes"`
	Replies   []Comment     `gorm:"foreignKey:ParentID" json:"replies"`
}

type CommentLike struct {
	ID        uint `gorm:"primaryKey" json:"id"`
	UserID    uint `json:"user_id"`
	CommentID uint `json:"comment_id"`
}

type Chat struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	User1ID     uint      `json:"user1_id"`
	User2ID     uint      `json:"user2_id"`
	User1       User      `gorm:"foreignKey:User1ID" json:"User1"`
	User2       User      `gorm:"foreignKey:User2ID" json:"User2"`
	UpdatedAt   time.Time `json:"updated_at"`
	UnreadCount int       `json:"unread_count" gorm:"-"`
}

type Message struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	ChatID    uint      `json:"chat_id"`
	SenderID  uint      `json:"sender_id"`
	Message   string    `json:"message"`
	IsRead    bool      `json:"is_read" gorm:"default:false"`
	IsEdited  bool      `json:"is_edited" gorm:"default:false"`
	CreatedAt time.Time `json:"created_at"`
}

type Notification struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `json:"user_id"`
	Type      string    `json:"type"` // like, comment, follow, message, reply, mention
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	IsRead    bool      `json:"is_read" gorm:"default:false"`
	CreatedAt time.Time `json:"created_at"`
}

type StoryView struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	StoryID   uint      `json:"story_id"`
	UserID    uint      `json:"user_id"`
	CreatedAt time.Time `json:"created_at"`
}
