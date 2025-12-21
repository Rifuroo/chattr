package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"

	"github.com/gin-gonic/gin"
)

func RouletteMatch(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	// In a real app, this would use a matching pool/queue.
	// For this prototype, we'll pick a random active user who isn't the current user.
	var randomUser models.User
	result := config.DB.Where("id != ?", userID).Order("RAND()").First(&randomUser)

	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No users available for matching"})
		return
	}

	// Create or find a chat
	var chat models.Chat
	err := config.DB.Where("(user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)",
		userID, randomUser.ID, randomUser.ID, userID).First(&chat).Error

	if err != nil {
		chat = models.Chat{
			User1ID: userID,
			User2ID: randomUser.ID,
		}
		config.DB.Create(&chat)
	}

	config.DB.Preload("User1").Preload("User2").First(&chat, chat.ID)

	c.JSON(http.StatusOK, chat)
}
