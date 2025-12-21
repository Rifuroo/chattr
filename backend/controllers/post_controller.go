package controllers

import (
	"net/http"
	"path/filepath"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func GetPosts(c *gin.Context) {
	var posts []models.Post
	if err := config.DB.Preload("User").Preload("Likes").
		Preload("Comments", "parent_id IS NULL"). // Only top-level comments
		Preload("Comments.User").
		Preload("Comments.Likes").
		Preload("Comments.Replies").
		Preload("Comments.Replies.User").
		Order("created_at desc").Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch posts"})
		return
	}

	c.JSON(http.StatusOK, posts)
}

func CreatePost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	content := c.PostForm("content")

	file, err := c.FormFile("image")
	imagePath := ""

	if err == nil {
		// Generate unique filename
		extension := filepath.Ext(file.Filename)
		newFileName := uuid.New().String() + extension
		imagePath = "uploads/" + newFileName

		if err := c.SaveUploadedFile(file, imagePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save image"})
			return
		}
	}

	post := models.Post{
		UserID:    userID,
		Content:   content,
		ImagePath: imagePath,
		CreatedAt: time.Now(),
	}

	if err := config.DB.Create(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}

	// Mentions
	services.HandleMentions(content, userID, "a post")

	config.DB.Preload("User").First(&post, post.ID)
	c.JSON(http.StatusCreated, post)
}
