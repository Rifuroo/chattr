package controllers

import (
	"fmt"
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"

	"github.com/gin-gonic/gin"
)

func GetUserProfile(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := config.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Privacy logic
	userID := c.MustGet("userID").(uint)
	if user.IsPrivate && userID != user.ID {
		var follows []models.Follow
		config.DB.Where("follower_id = ? AND following_id = ?", userID, user.ID).Limit(1).Find(&follows)
		if len(follows) == 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "This account is private", "user": user})
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
	// Bio can be empty string if user clears it, but PostForm returns empty string if not present.
	// For simplicity, we assume if client sends it, we update it.
	// But distinguishing "not sent" vs "empty" in Form is tricky without checking presence.
	// We'll trust the client sends current value if not changing.
	user.Bio = bio

	if isPrivateStr == "true" {
		user.IsPrivate = true
	} else if isPrivateStr == "false" {
		user.IsPrivate = false
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

	var following models.User
	if err := config.DB.First(&following, followingID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User to follow not found"})
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
	var sender models.User
	config.DB.First(&sender, followerID)
	title := "New Follower"
	body := sender.Username + " started following you!"
	services.CreateNotification(following.ID, "follow", title, body)
	if following.FCMToken != "" {
		services.SendFCMNotification(following.FCMToken, title, body)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Followed successfully"})
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
