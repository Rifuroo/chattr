package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"time"

	"github.com/gin-gonic/gin"
)

func CreateHighlight(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var input struct {
		Title      string `json:"title" binding:"required"`
		CoverImage string `json:"cover_image"`
		IsShared   bool   `json:"is_shared"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	highlight := models.Highlight{
		CreatorID:  userID,
		Title:      input.Title,
		CoverImage: input.CoverImage,
		IsShared:   input.IsShared,
		CreatedAt:  time.Now(),
	}

	if err := config.DB.Create(&highlight).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create highlight"})
		return
	}

	c.JSON(http.StatusCreated, highlight)
}

func AddHighlightMember(c *gin.Context) {
	creatorID := c.MustGet("userID").(uint)
	highlightID := c.Param("id")
	var input struct {
		UserID uint `json:"user_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var highlight models.Highlight
	if err := config.DB.First(&highlight, highlightID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Highlight not found"})
		return
	}

	if highlight.CreatorID != creatorID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Only creator can add members"})
		return
	}

	member := models.HighlightMember{
		HighlightID: highlight.ID,
		UserID:      input.UserID,
	}

	if err := config.DB.Create(&member).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add member"})
		return
	}

	c.JSON(http.StatusCreated, member)
}

func AddHighlightItem(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	highlightID := c.Param("id")
	var input struct {
		StoryID uint `json:"story_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var highlight models.Highlight
	if err := config.DB.Preload("Members").First(&highlight, highlightID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Highlight not found"})
		return
	}

	// Check if user is creator or member
	isMember := highlight.CreatorID == userID
	if !isMember {
		for _, m := range highlight.Members {
			if m.UserID == userID {
				isMember = true
				break
			}
		}
	}

	if !isMember {
		c.JSON(http.StatusForbidden, gin.H{"error": "You are not a member of this highlight"})
		return
	}

	item := models.HighlightItem{
		HighlightID: highlight.ID,
		StoryID:     input.StoryID,
		CreatedAt:   time.Now(),
	}

	if err := config.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add item"})
		return
	}

	c.JSON(http.StatusCreated, item)
}

func GetHighlights(c *gin.Context) {
	userID := c.Param("userId")
	var highlights []models.Highlight
	config.DB.Where("creator_id = ? OR id IN (SELECT highlight_id FROM highlight_members WHERE user_id = ?)", userID, userID).
		Preload("Members.User").Preload("Items.Story").Order("created_at desc").Find(&highlights)

	c.JSON(http.StatusOK, highlights)
}
