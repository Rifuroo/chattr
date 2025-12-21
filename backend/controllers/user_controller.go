package controllers

import (
	"fmt"
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"
	"time"

	"github.com/gin-gonic/gin"
)

func GetUserProfile(c *gin.Context) {
	id := c.Param("id")
	userID := c.MustGet("userID").(uint)
	var user models.User
	if err := config.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Block check
	var block models.Block
	if config.DB.Where("(user_id = ? AND blocked_id = ?) OR (user_id = ? AND blocked_id = ?)",
		userID, user.ID, user.ID, userID).First(&block).Error == nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "User is blocked", "blocked": true})
		return
	}

	// Privacy logic
	if user.IsPrivate && userID != user.ID {
		var follow models.Follow
		if config.DB.Where("follower_id = ? AND following_id = ?", userID, user.ID).First(&follow).Error != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "This account is private", "user": user, "is_private": true})
			return
		}
	}

	// Calculate counts
	var followersCount int64
	var followingCount int64
	var postsCount int64

	config.DB.Model(&models.Follow{}).Where("following_id = ?", user.ID).Count(&followersCount)
	config.DB.Model(&models.Follow{}).Where("follower_id = ?", user.ID).Count(&followingCount)
	config.DB.Model(&models.Post{}).Where("user_id = ?", user.ID).Count(&postsCount)

	user.FollowersCount = followersCount
	user.FollowingCount = followingCount
	user.PostsCount = postsCount

	c.JSON(http.StatusOK, user)
}

func UpdateProfile(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var user models.User
	if err := config.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Read fields from PostForm (multipart/form-data)
	name := c.PostForm("name")
	bio := c.PostForm("bio")
	isPrivateStr := c.PostForm("is_private")

	if name != "" {
		user.Name = name
	}
	user.Bio = bio

	if isPrivateStr == "true" {
		user.IsPrivate = true
	} else if isPrivateStr == "false" {
		user.IsPrivate = false
	}

	isGhostStr := c.PostForm("is_ghost_mode")
	if isGhostStr == "true" {
		user.IsGhostMode = true
	} else if isGhostStr == "false" {
		user.IsGhostMode = false
	}

	spotifyTrackID := c.PostForm("spotify_track_id")
	if spotifyTrackID != "" {
		user.SpotifyTrackID = spotifyTrackID
	}

	moodEmoji := c.PostForm("mood_emoji")
	moodText := c.PostForm("mood_text")
	if moodEmoji != "" {
		user.MoodEmoji = moodEmoji
	}
	if moodText != "" {
		user.MoodText = moodText
	}

	profileTheme := c.PostForm("profile_theme")
	if profileTheme != "" {
		user.ProfileTheme = profileTheme
	}

	// Handle file upload for avatar
	file, err := c.FormFile("avatar")
	if err == nil {
		filename := fmt.Sprintf("avatar_%d_%s", userID, file.Filename)
		c.SaveUploadedFile(file, "uploads/"+filename)
		user.Avatar = "/uploads/" + filename
	}

	config.DB.Save(&user)
	c.JSON(http.StatusOK, user)
}

func GetMemoryLane(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	now := time.Now()

	var posts []models.Post
	// Fetch posts from the same day/month in previous years
	if err := config.DB.Where("user_id = ? AND MONTH(created_at) = ? AND DAY(created_at) = ? AND YEAR(created_at) < ?",
		userID, now.Month(), now.Day(), now.Year()).
		Preload("User").Preload("Media").Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch memory lane"})
		return
	}

	c.JSON(http.StatusOK, posts)
}

func ToggleGhostMode(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var user models.User
	if err := config.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	user.IsGhostMode = !user.IsGhostMode
	config.DB.Save(&user)

	c.JSON(http.StatusOK, gin.H{"is_ghost_mode": user.IsGhostMode})
}

func SearchUsers(c *gin.Context) {
	query := c.Query("q")
	var users []models.User
	config.DB.Where("username LIKE ? OR name LIKE ?", "%"+query+"%", "%"+query+"%").Limit(20).Find(&users)
	c.JSON(http.StatusOK, users)
}

func FollowUser(c *gin.Context) {
	followerID := c.MustGet("userID").(uint)
	followingID := c.Param("id")

	if fmt.Sprintf("%d", followerID) == followingID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You cannot follow yourself"})
		return
	}

	var sender models.User
	config.DB.First(&sender, followerID)

	var following models.User
	if err := config.DB.First(&following, followingID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User to follow not found"})
		return
	}

	// Logic for private accounts
	if following.IsPrivate {
		// Check if request already exists
		var existingRequest models.FollowRequest
		if config.DB.Where("follower_id = ? AND user_id = ? AND status = 'pending'", followerID, following.ID).First(&existingRequest).Error == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Follow request already pending"})
			return
		}

		request := models.FollowRequest{
			FollowerID: followerID,
			UserID:     following.ID,
		}
		config.DB.Create(&request)

		// Notification for request
		services.CreateNotification(following.ID, "follow_request", "New Follow Request", sender.Username+" wants to follow you.")

		c.JSON(http.StatusOK, gin.H{"message": "Follow request sent", "status": "pending"})
		return
	}

	follow := models.Follow{
		FollowerID:  followerID,
		FollowingID: following.ID,
	}

	if err := config.DB.Create(&follow).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Already following or database error"})
		return
	}

	// Notification
	title := "New Follower"
	body := sender.Username + " started following you!"
	services.CreateNotification(following.ID, "follow", title, body)
	if following.FCMToken != "" {
		services.SendFCMNotification(following.FCMToken, title, body, map[string]string{
			"type":    "follow",
			"user_id": fmt.Sprintf("%d", followerID),
		})
	}

	// Broadcast Flash Event (Global Ticker)
	services.Hub.Broadcast(services.ChattrEvent{
		Type:      "follow",
		Title:     "New Growth!",
		Body:      sender.Username + " started following " + following.Username,
		Username:  sender.Username,
		Avatar:    sender.Avatar,
		CreatedAt: time.Now().Format(time.RFC3339),
	})

	c.JSON(http.StatusOK, gin.H{"message": "Followed successfully", "status": "following"})
}

func UnfollowUser(c *gin.Context) {
	followerID := c.MustGet("userID").(uint)
	followingID := c.Param("id")

	config.DB.Where("follower_id = ? AND following_id = ?", followerID, followingID).Delete(&models.Follow{})
	c.JSON(http.StatusOK, gin.H{"message": "Unfollowed successfully"})
}

func UpdateFCMToken(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var input struct {
		Token string `json:"token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := config.DB.Model(&models.User{}).Where("id = ?", userID).Update("fcm_token", input.Token).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update FCM token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "FCM token updated"})
}

func GetFollowers(c *gin.Context) {
	userID := c.Param("id")
	var follows []models.Follow
	var users []models.User

	// Find all follow records where this user is being followed
	config.DB.Where("following_id = ?", userID).Find(&follows)

	// Collect follower IDs
	var followerIDs []uint
	for _, f := range follows {
		followerIDs = append(followerIDs, f.FollowerID)
	}

	// Fetch users by IDs
	if len(followerIDs) > 0 {
		config.DB.Where("id IN ?", followerIDs).Find(&users)
	}

	c.JSON(http.StatusOK, users)
}

func GetFollowing(c *gin.Context) {
	userID := c.Param("id")
	var follows []models.Follow
	var users []models.User

	// Find all follow records where this user is the follower
	config.DB.Where("follower_id = ?", userID).Find(&follows)

	// Collect following IDs
	var followingIDs []uint
	for _, f := range follows {
		followingIDs = append(followingIDs, f.FollowingID)
	}

	// Fetch users by IDs
	if len(followingIDs) > 0 {
		config.DB.Where("id IN ?", followingIDs).Find(&users)
	}

	c.JSON(http.StatusOK, users)
}
