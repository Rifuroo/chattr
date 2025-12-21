package controllers

import (
	"fmt"
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func CreateStory(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	file, err := c.FormFile("media")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Media is required"})
		return
	}

	filename := fmt.Sprintf("story_%d_%s", userID, file.Filename)
	c.SaveUploadedFile(file, "uploads/"+filename)

	isAudio := c.PostForm("is_audio") == "true"
	story := models.Story{
		UserID:    userID,
		MediaPath: "/uploads/" + filename,
		ExpiresAt: time.Now().Add(24 * time.Hour), // Expire in 24 hours
		IsAudio:   isAudio,
	}

	if err := config.DB.Create(&story).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create story"})
		return
	}

	services.UpdateQuestProgress(userID, "story")

	c.JSON(http.StatusCreated, story)
}

func GetStories(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var followings []models.Follow
	config.DB.Where("follower_id = ?", userID).Find(&followings)

	var followingIDs []uint
	followingIDs = append(followingIDs, userID) // Include self
	for _, f := range followings {
		followingIDs = append(followingIDs, f.FollowingID)
	}

	var stories []models.Story
	// Only fetch stories from self and followings, where ExpiresAt is in the future
	config.DB.Preload("User").
		Where("user_id IN ? AND expires_at > ?", followingIDs, time.Now()).
		Order("created_at desc").
		Find(&stories)

	c.JSON(http.StatusOK, stories)
}

func ViewStory(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	storyIDStr := c.Param("id")
	storyID, _ := strconv.Atoi(storyIDStr)

	// Check if already viewed
	var existingView models.StoryView
	result := config.DB.Where("story_id = ? AND user_id = ?", storyID, userID).First(&existingView)

	if result.RowsAffected == 0 {
		view := models.StoryView{
			StoryID:   uint(storyID),
			UserID:    userID,
			CreatedAt: time.Now(),
		}
		config.DB.Create(&view)

		// Notify owner
		var story models.Story
		if err := config.DB.Preload("User").First(&story, storyID).Error; err == nil {
			if story.UserID != userID {
				var viewer models.User
				config.DB.First(&viewer, userID)
				title := "Story View"
				body := viewer.Username + " viewed your story!"
				services.CreateNotification(story.UserID, "story_view", title, body)
				if story.User.FCMToken != "" {
					services.SendFCMNotification(story.User.FCMToken, title, body, map[string]string{
						"type":     "story_view",
						"story_id": strconv.Itoa(int(story.ID)),
					})
				}
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Story viewed"})
}
