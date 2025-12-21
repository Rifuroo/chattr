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

func DeletePost(c *gin.Context) {
	postID := c.Param("id")
	userID := c.MustGet("userID").(uint)

	var post models.Post
	if err := config.DB.First(&post, postID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	// Verify post belongs to user
	if post.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own posts"})
		return
	}

	// Delete associated likes
	config.DB.Where("post_id = ?", postID).Delete(&models.Like{})

	// Delete associated comments (and their likes)
	var comments []models.Comment
	config.DB.Where("post_id = ?", postID).Find(&comments)
	for _, comment := range comments {
		config.DB.Where("comment_id = ?", comment.ID).Delete(&models.CommentLike{})
	}
	config.DB.Where("post_id = ?", postID).Delete(&models.Comment{})

	// Delete image file if exists
	if post.ImagePath != "" {
		// Note: os.Remove would be used here, but we'll skip for now
		// os.Remove(post.ImagePath)
	}

	// Delete post
	if err := config.DB.Delete(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete post"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Post deleted successfully"})
}
