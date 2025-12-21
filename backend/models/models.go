package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID             uint           `gorm:"primaryKey" json:"id"`
	Name           string         `json:"name"`
	Username       string         `gorm:"type:varchar(191);uniqueIndex" json:"username"`
	Email          string         `gorm:"type:varchar(191);uniqueIndex" json:"email"`
	Password       string         `json:"-"`
	Bio            string         `json:"bio"`
	Avatar         string         `json:"avatar"`
	IsPrivate      bool           `json:"is_private" gorm:"default:false"`
	IsVerified     bool           `json:"is_verified" gorm:"default:false"`
	SpotifyTrackID string         `json:"spotify_track_id"` // For Profile Music
	MoodEmoji      string         `json:"mood_emoji"`
	MoodText       string         `json:"mood_text"`
	ProfileTheme   string         `json:"profile_theme" gorm:"default:'default'"`
	FCMToken       string         `json:"fcm_token"`
	IsGhostMode    bool           `json:"is_ghost_mode" gorm:"default:false"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`

	FollowersCount int64 `json:"followers_count" gorm:"-"`
	FollowingCount int64 `json:"following_count" gorm:"-"`
	PostsCount     int64 `json:"posts_count" gorm:"-"`
}

type Follow struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	FollowerID  uint      `gorm:"index" json:"follower_id"`
	FollowingID uint      `gorm:"index" json:"following_id"`
	Follower    User      `gorm:"foreignKey:FollowerID" json:"follower"`
	Following   User      `gorm:"foreignKey:FollowingID" json:"following"`
	CreatedAt   time.Time `json:"created_at"`
}

type Post struct {
	ID             uint        `gorm:"primaryKey" json:"id"`
	UserID         uint        `gorm:"index" json:"user_id"`
	User           User        `json:"user"`
	Content        string      `json:"content"`
	ImagePath      string      `json:"image_path"`
	CreatedAt      time.Time   `gorm:"index" json:"created_at"`
	Likes          []Like      `json:"likes"`
	Comments       []Comment   `json:"comments"`
	Media          []PostMedia `json:"media" gorm:"foreignKey:PostID"`
	OriginalPostID *uint       `json:"original_post_id"`
	OriginalPost   *Post       `json:"original_post" gorm:"foreignKey:OriginalPostID"`
	Poll           *Poll       `json:"poll" gorm:"foreignKey:PostID"`
	ViewCount      int64       `json:"view_count" gorm:"default:0"`
	SpotifyTrackID string      `json:"spotify_track_id"`
	IsFlash        bool        `json:"is_flash" gorm:"default:false"`
	ExpiresAt      *time.Time  `json:"expires_at"`
}

type Poll struct {
	ID              uint         `gorm:"primaryKey" json:"id"`
	PostID          uint         `gorm:"index" json:"post_id"`
	Question        string       `json:"question"`
	Options         []PollOption `json:"options" gorm:"foreignKey:PollID"`
	IsCollaborative bool         `json:"is_collaborative" gorm:"default:false"`
	ExpiresAt       time.Time    `json:"expires_at"`
	Votes           []PollVote   `json:"votes" gorm:"foreignKey:PollID"`
}

type PollOption struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	PollID      uint   `gorm:"index" json:"poll_id"`
	Option      string `json:"option"`
	CreatedByID uint   `json:"created_by_id"`
	CreatedBy   User   `json:"created_by" gorm:"foreignKey:CreatedByID"`
}

type PollVote struct {
	ID          uint `gorm:"primaryKey" json:"id"`
	PollID      uint `gorm:"index" json:"poll_id"`
	UserID      uint `gorm:"index" json:"user_id"`
	OptionIndex int  `json:"option_index"`
}

type PostMedia struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	PostID    uint      `json:"post_id"`
	Path      string    `json:"path"`
	Type      string    `json:"type"` // image, video
	CreatedAt time.Time `json:"created_at"`
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
	IsAudio   bool      `json:"is_audio" gorm:"default:false"`
}

type Like struct {
	ID     uint `gorm:"primaryKey" json:"id"`
	UserID uint `gorm:"index" json:"user_id"`
	PostID uint `gorm:"index" json:"post_id"`
}

type Comment struct {
	ID        uint          `gorm:"primaryKey" json:"id"`
	UserID    uint          `json:"user_id"`
	User      User          `json:"user"`
	PostID    uint          `gorm:"index" json:"post_id"`
	ParentID  *uint         `json:"parent_id"`
	Content   string        `json:"content"`
	CreatedAt time.Time     `json:"created_at"`
	Likes     []CommentLike `json:"likes"`
	Replies   []Comment     `gorm:"foreignKey:ParentID" json:"replies"`
	GIFUrl    string        `json:"gif_url"`
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
	LastMessage string    `json:"last_message"`
	UpdatedAt   time.Time `gorm:"index" json:"updated_at"`
	UnreadCount int       `json:"unread_count" gorm:"-"`
}

type Message struct {
	ID        uint       `gorm:"primaryKey" json:"id"`
	ChatID    uint       `gorm:"index" json:"chat_id"`
	SenderID  uint       `json:"sender_id"`
	Message   string     `json:"message"`
	Type      string     `json:"type" gorm:"default:'text'"` // text, image, video, voice, gif
	MediaPath string     `json:"media_path"`
	IsSecret  bool       `json:"is_secret" gorm:"default:false"`
	ExpiresAt *time.Time `json:"expires_at"`
	CreatedAt time.Time  `gorm:"index" json:"updated_at"`
}

type FollowRequest struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	FollowerID uint      `gorm:"index" json:"follower_id"`
	UserID     uint      `gorm:"index" json:"user_id"`
	Status     string    `json:"status" gorm:"default:'pending'"`
	CreatedAt  time.Time `json:"created_at"`
	Follower   User      `gorm:"foreignKey:FollowerID" json:"follower"`
}

type Block struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"index" json:"user_id"`
	BlockedID uint      `gorm:"index" json:"blocked_id"`
	CreatedAt time.Time `json:"created_at"`
}

type Tell struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"index" json:"user_id"`
	Content   string    `json:"content"`
	IsRead    bool      `json:"is_read" gorm:"default:false"`
	CreatedAt time.Time `json:"created_at"`
}

type Notification struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `json:"user_id"`
	Type      string    `json:"type"`
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

type SavedPost struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"uniqueIndex:idx_user_post" json:"user_id"`
	PostID    uint      `gorm:"uniqueIndex:idx_user_post" json:"post_id"`
	CreatedAt time.Time `json:"created_at"`
	Post      Post      `json:"post"`
}

type SharedStory struct {
	ID          uint                `gorm:"primaryKey" json:"id"`
	CreatorID   uint                `json:"creator_id"`
	Creator     User                `gorm:"foreignKey:CreatorID" json:"creator"`
	Title       string              `json:"title"`
	Description string              `json:"description"`
	CoverImage  string              `json:"cover_image"`
	Members     []SharedStoryMember `json:"members"`
	Media       []SharedStoryMedia  `json:"media"`
	CreatedAt   time.Time           `json:"created_at"`
	UpdatedAt   time.Time           `updated_at`
}

type SharedStoryMember struct {
	ID            uint   `gorm:"primaryKey" json:"id"`
	SharedStoryID uint   `gorm:"index" json:"shared_story_id"`
	UserID        uint   `gorm:"index" json:"user_id"`
	User          User   `json:"user"`
	Role          string `json:"role" gorm:"default:'member'"`
}

type SharedStoryMedia struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	SharedStoryID uint      `gorm:"index" json:"shared_story_id"`
	UserID        uint      `json:"user_id"`
	User          User      `json:"user"`
	Path          string    `json:"path"`
	Type          string    `json:"type"`
	CreatedAt     time.Time `json:"created_at"`
}

type Quest struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	Points       int       `json:"points"`
	TargetAction string    `json:"target_action"`
	TargetCount  int       `json:"target_count"`
	CreatedAt    time.Time `json:"created_at"`
}

type UserQuest struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"index" json:"user_id"`
	QuestID     uint      `gorm:"index" json:"quest_id"`
	Quest       Quest     `json:"quest"`
	Progress    int       `json:"progress"`
	IsCompleted bool      `json:"is_completed" gorm:"default:false"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Highlight struct {
	ID         uint              `gorm:"primaryKey" json:"id"`
	CreatorID  uint              `json:"creator_id"`
	Creator    User              `gorm:"foreignKey:CreatorID" json:"creator"`
	Title      string            `json:"title"`
	CoverImage string            `json:"cover_image"`
	Members    []HighlightMember `json:"members"`
	Items      []HighlightItem   `json:"items"`
	IsShared   bool              `json:"is_shared" gorm:"default:false"`
	CreatedAt  time.Time         `json:"created_at"`
}

type HighlightMember struct {
	ID          uint `gorm:"primaryKey" json:"id"`
	HighlightID uint `gorm:"index" json:"highlight_id"`
	UserID      uint `gorm:"index" json:"user_id"`
	User        User `json:"user"`
}

type HighlightItem struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	HighlightID uint      `gorm:"index" json:"highlight_id"`
	StoryID     uint      `json:"story_id"`
	Story       Story     `json:"story"`
	CreatedAt   time.Time `json:"created_at"`
}
