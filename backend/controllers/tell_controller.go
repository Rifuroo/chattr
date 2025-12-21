package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"
	"strconv"

	"github.com/gin-gonic/gin"
)

// SendTell sends an anonymous message to a user
func SendTell(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, _ := strconv.Atoi(userIDStr)

	var input struct {
		Content string `json:"content" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tell := models.Tell{
		UserID:  uint(userID),
		Content: input.Content,
	}

	if err := config.DB.Create(&tell).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send tell"})
		return
	}

	// Notification for recipient (without sender info)
	services.CreateNotification(uint(userID), "tell", "New Anonymous Tell", "Someone sent you a new anonymous message!")

	c.JSON(http.StatusOK, gin.H{"message": "Tell sent anonymously"})
}

// GetMyTells retrieves anonymous messages for the current user
func GetMyTells(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var tells []models.Tell
	config.DB.Where("user_id = ?", userID).Order("created_at DESC").Find(&tells)

	c.JSON(http.StatusOK, tells)
}

// MarkTellAsRead marks a tell as read
func MarkTellAsRead(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	tellIDStr := c.Param("id")
	tellID, _ := strconv.Atoi(tellIDStr)

	config.DB.Model(&models.Tell{}).Where("id = ? AND user_id = ?", tellID, userID).Update("is_read", true)
	c.JSON(http.StatusOK, gin.H{"message": "Tell marked as read"})
}
