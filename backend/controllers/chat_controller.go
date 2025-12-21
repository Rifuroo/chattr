package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func StartChat(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var input struct {
		OtherUserID uint `json:"other_user_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if chat already exists
	var chat models.Chat
	result := config.DB.Where("(user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)",
		userID, input.OtherUserID, input.OtherUserID, userID).First(&chat)

	if result.RowsAffected == 0 {
		chat = models.Chat{
			User1ID:   userID,
			User2ID:   input.OtherUserID,
			UpdatedAt: time.Now(),
		}
		config.DB.Create(&chat)
	}

	// Fetch the chat with users preloaded
	config.DB.Preload("User1").Preload("User2").First(&chat, chat.ID)

	c.JSON(http.StatusOK, chat)
}

func GetChats(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var chats []models.Chat
	config.DB.Where("user1_id = ? OR user2_id = ?", userID, userID).
		Preload("User1").Preload("User2").Order("updated_at desc").Find(&chats)

	// Calculate unread counts for each chat
	for i := range chats {
		var count int64
		config.DB.Model(&models.Message{}).
			Where("chat_id = ? AND sender_id != ? AND is_read = ?", chats[i].ID, userID, false).
			Count(&count)
		chats[i].UnreadCount = int(count)
	}

	c.JSON(http.StatusOK, chats)
}

func GetMessages(c *gin.Context) {
	chatIDStr := c.Param("id")
	chatID, _ := strconv.Atoi(chatIDStr)

	var messages []models.Message
	config.DB.Where("chat_id = ?", chatID).Order("created_at asc").Find(&messages)

	c.JSON(http.StatusOK, messages)
}

func SendMessage(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	chatIDStr := c.Param("id")
	chatID, _ := strconv.Atoi(chatIDStr)

	var input struct {
		Message string `json:"message" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg := models.Message{
		ChatID:    uint(chatID),
		SenderID:  userID,
		Message:   input.Message,
		CreatedAt: time.Now(),
	}

	if err := config.DB.Create(&msg).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	// Notification
	var chat models.Chat
	config.DB.Preload("User1").Preload("User2").First(&chat, chatID)

	var sender models.User
	var recipient models.User
	config.DB.First(&sender, userID)

	if chat.User1ID == userID {
		recipient = chat.User2
	} else {
		recipient = chat.User1
	}

	if recipient.FCMToken != "" {
		services.SendFCMNotification(recipient.FCMToken, "New Message from "+sender.Username, msg.Message)
	}
	services.CreateNotification(recipient.ID, "message", "New Message from "+sender.Username, msg.Message)

	// Update chat updated_at
	config.DB.Model(&models.Chat{}).Where("id = ?", chatID).Update("updated_at", time.Now())

	c.JSON(http.StatusCreated, msg)
}
func UpdateMessage(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	msgIDStr := c.Param("messageId")
	msgID, _ := strconv.Atoi(msgIDStr)

	var input struct {
		Message string `json:"message" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var msg models.Message
	if err := config.DB.First(&msg, msgID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Message not found"})
		return
	}

	if msg.SenderID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only edit your own messages"})
		return
	}

	msg.Message = input.Message
	msg.IsEdited = true
	config.DB.Save(&msg)

	c.JSON(http.StatusOK, msg)
}

func DeleteMessage(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	msgIDStr := c.Param("messageId")
	msgID, _ := strconv.Atoi(msgIDStr)

	var msg models.Message
	if err := config.DB.First(&msg, msgID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Message not found"})
		return
	}

	if msg.SenderID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own messages"})
		return
	}

	config.DB.Delete(&msg)

	c.JSON(http.StatusOK, gin.H{"message": "Message deleted"})
}

func MarkMessagesAsRead(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	chatIDStr := c.Param("id")
	chatID, _ := strconv.Atoi(chatIDStr)

	err := config.DB.Model(&models.Message{}).
		Where("chat_id = ? AND sender_id != ?", chatID, userID).
		Update("is_read", true).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark messages as read"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Messages marked as read"})
}
