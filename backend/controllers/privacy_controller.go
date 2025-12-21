package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"
	"strconv"

	"github.com/gin-gonic/gin"
)

// ToggleBlock blocks or unblocks a user
func ToggleBlock(c *gin.Context) {
	currentUserID := c.MustGet("userID").(uint)
	blockedIDStr := c.Param("id")
	blockedID, _ := strconv.Atoi(blockedIDStr)

	if uint(blockedID) == currentUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You cannot block yourself"})
		return
	}

	var block models.Block
	err := config.DB.Where("user_id = ? AND blocked_id = ?", currentUserID, blockedID).First(&block).Error

	if err == nil {
		// Already blocked, so unblock
		config.DB.Delete(&block)

		// Optional: also remove any follow relationship that might have existed
		config.DB.Where("(follower_id = ? AND following_id = ?) OR (follower_id = ? AND following_id = ?)",
			currentUserID, blockedID, blockedID, currentUserID).Delete(&models.Follow{})

		c.JSON(http.StatusOK, gin.H{"blocked": false})
	} else {
		// Not blocked, so block
		newBlock := models.Block{
			UserID:    currentUserID,
			BlockedID: uint(blockedID),
		}
		config.DB.Create(&newBlock)

		// Remove follows when blocking
		config.DB.Where("(follower_id = ? AND following_id = ?) OR (follower_id = ? AND following_id = ?)",
			currentUserID, blockedID, blockedID, currentUserID).Delete(&models.Follow{})

		c.JSON(http.StatusOK, gin.H{"blocked": true})
	}
}

// GetFollowRequests returns pending follow requests for the current user
func GetFollowRequests(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var requests []models.FollowRequest
	config.DB.Preload("Follower").Where("user_id = ? AND status = 'pending'", userID).Find(&requests)

	c.JSON(http.StatusOK, requests)
}

// RespondToFollowRequest accepts or rejects a follow request
func RespondToFollowRequest(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	requestIDStr := c.Param("id")
	requestID, _ := strconv.Atoi(requestIDStr)

	var input struct {
		Action string `json:"action"` // accept or reject
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var request models.FollowRequest
	if err := config.DB.Where("id = ? AND user_id = ?", requestID, userID).First(&request).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Request not found"})
		return
	}

	if input.Action == "accept" {
		request.Status = "accepted"
		config.DB.Save(&request)

		// Create actual follow relationship
		follow := models.Follow{
			FollowerID:  request.FollowerID,
			FollowingID: userID,
		}
		config.DB.Create(&follow)

		c.JSON(http.StatusOK, gin.H{"message": "Follow request accepted"})
	} else {
		request.Status = "rejected"
		config.DB.Save(&request)
		c.JSON(http.StatusOK, gin.H{"message": "Follow request rejected"})
	}
}
