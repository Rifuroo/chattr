package controllers

import (
	"fmt"
	"net/http"
	"path/filepath"
	"social-media-backend/config"
	"social-media-backend/models"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func CreateSharedStory(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	title := c.PostForm("title")
	description := c.PostForm("description")

	story := models.SharedStory{
		CreatorID:   userID,
		Title:       title,
		Description: description,
	}

	file, err := c.FormFile("cover")
	if err == nil {
		filename := uuid.New().String() + filepath.Ext(file.Filename)
		if err := c.SaveUploadedFile(file, "uploads/"+filename); err == nil {
			story.CoverImage = "/uploads/" + filename
		}
	}

	if err := config.DB.Create(&story).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create story"})
		return
	}

	// Add creator as member
	member := models.SharedStoryMember{
		SharedStoryID: story.ID,
		UserID:        userID,
		Role:          "creator",
	}
	config.DB.Create(&member)

	c.JSON(http.StatusCreated, story)
}

func GetSharedStories(c *gin.Context) {
	var stories []models.SharedStory
	// Get stories where user is a member
	userID := c.MustGet("userID").(uint)

	config.DB.Joins("JOIN shared_story_members ON shared_story_members.shared_story_id = shared_stories.id").
		Where("shared_story_members.user_id = ?", userID).
		Preload("Creator").
		Preload("Members.User").
		Preload("Media.User").
		Find(&stories)

	c.JSON(http.StatusOK, stories)
}

func GetSharedStory(c *gin.Context) {
	id := c.Param("id")
	var story models.SharedStory
	if err := config.DB.Preload("Creator").Preload("Members.User").Preload("Media.User").First(&story, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Story not found"})
		return
	}
	c.JSON(http.StatusOK, story)
}

func AddStoryMedia(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	storyIDStr := c.Param("id")
	storyID, _ := strconv.Atoi(storyIDStr)

	// Check membership
	var count int64
	config.DB.Model(&models.SharedStoryMember{}).Where("shared_story_id = ? AND user_id = ?", storyID, userID).Count(&count)
	if count == 0 {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not a member of this story"})
		return
	}

	file, err := c.FormFile("media")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Media is required"})
		return
	}

	filename := fmt.Sprintf("shared_story_%d_%d_%s", storyID, userID, uuid.New().String()+filepath.Ext(file.Filename))
	if err := c.SaveUploadedFile(file, "uploads/"+filename); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not save file"})
		return
	}

	media := models.SharedStoryMedia{
		SharedStoryID: uint(storyID),
		UserID:        userID,
		Path:          "/uploads/" + filename,
		Type:          c.DefaultPostForm("type", "image"),
	}

	if err := config.DB.Create(&media).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not add media"})
		return
	}

	c.JSON(http.StatusCreated, media)
}

func JoinSharedStory(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	storyIDStr := c.Param("id")
	storyID, _ := strconv.Atoi(storyIDStr)

	var member models.SharedStoryMember
	if err := config.DB.Where("shared_story_id = ? AND user_id = ?", storyID, userID).First(&member).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Already a member"})
		return
	}

	member = models.SharedStoryMember{
		SharedStoryID: uint(storyID),
		UserID:        userID,
		Role:          "member",
	}

	if err := config.DB.Create(&member).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not join story"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Joined successfully"})
}
