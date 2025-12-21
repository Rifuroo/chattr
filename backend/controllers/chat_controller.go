package controllers

import (
	"net/http"
	"path/filepath"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/services"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

	var msg models.Message
	msg.ChatID = uint(chatID)
	msg.SenderID = userID
	msg.CreatedAt = time.Now()
	msg.Type = "text" // Default

	// Check content type
	if c.ContentType() == "application/json" {
		var input struct {
			Message   string `json:"message"`
			Type      string `json:"type"`
			GIFUrl    string `json:"gif_url"`
			IsSecret  bool   `json:"is_secret"`
			ExpiresIn int    `json:"expires_in"` // in minutes
		}
		if err := c.ShouldBindJSON(&input); err == nil {
			msg.Message = input.Message
			if input.Type != "" {
				msg.Type = input.Type
			}
			if input.GIFUrl != "" {
				msg.MediaPath = input.GIFUrl
				msg.Type = "gif"
			}
			if input.IsSecret {
				msg.IsSecret = true
				if input.ExpiresIn > 0 {
					expiration := time.Now().Add(time.Duration(input.ExpiresIn) * time.Minute)
					msg.ExpiresAt = &expiration
				}
			}
		}
	} else {
		// Multipart/form-data
		msg.Message = c.PostForm("message")
		msg.Type = c.PostForm("type")
		if msg.Type == "" {
			msg.Type = "text"
		}

		if c.PostForm("is_secret") == "true" {
			msg.IsSecret = true
			expiresIn, _ := strconv.Atoi(c.PostForm("expires_in"))
			if expiresIn > 0 {
				expiration := time.Now().Add(time.Duration(expiresIn) * time.Minute)
				msg.ExpiresAt = &expiration
			}
		}

		file, err := c.FormFile("media")
		if err == nil {
			filename := uuid.New().String() + filepath.Ext(file.Filename)
			savePath := "uploads/" + filename
			if err := c.SaveUploadedFile(file, savePath); err == nil {
				msg.MediaPath = "/" + savePath
				// Auto-detect type if not provided
				if msg.Type == "text" {
					ext := filepath.Ext(file.Filename)
					if ext == ".mp4" || ext == ".mov" {
						msg.Type = "video"
					} else if ext == ".mp3" || ext == ".m4a" || ext == ".wav" {
						msg.Type = "voice"
					} else {
						msg.Type = "image"
					}
				}
			}
		}
	}

	if msg.Message == "" && msg.MediaPath == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Message or media is required"})
		return
	}

	if err := config.DB.Create(&msg).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	// Notification & Chat update
	var chat models.Chat
	config.DB.Preload("User1").Preload("User2").First(&chat, chatID)

	var sender models.User
	config.DB.First(&sender, userID)

	recipientID := chat.User1ID
	if userID == chat.User1ID {
		recipientID = chat.User2ID
	}

	var recipient models.User
	config.DB.First(&recipient, recipientID)

	notificationBody := msg.Message
	if msg.IsSecret {
		notificationBody = "Sent you a secret message 🕵️"
	} else if msg.Type != "text" {
		notificationBody = "Sent a " + msg.Type
	}

	if recipient.FCMToken != "" {
		services.SendFCMNotification(recipient.FCMToken, "New Message from "+sender.Username, notificationBody, map[string]string{
			"type":    "message",
			"chat_id": strconv.Itoa(int(chat.ID)),
		})
	}
	services.CreateNotification(recipient.ID, "message", "New Message from "+sender.Username, notificationBody)

	config.DB.Model(&models.Chat{}).Where("id = ?", chatID).Updates(map[string]interface{}{
		"updated_at":   time.Now(),
		"last_message": notificationBody,
	})

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
