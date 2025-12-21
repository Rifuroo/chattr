package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"strconv"

	"github.com/gin-gonic/gin"
)

func GetNotifications(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var notifications []models.Notification
	config.DB.Where("user_id = ?", userID).Order("created_at desc").Find(&notifications)
	c.JSON(http.StatusOK, notifications)
}

func MarkNotificationAsRead(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)
	userID := c.MustGet("userID").(uint)

	var notification models.Notification
	if err := config.DB.First(&notification, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
		return
	}

	if notification.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized"})
		return
	}

	notification.IsRead = true
	config.DB.Save(&notification)
	c.JSON(http.StatusOK, notification)
}
