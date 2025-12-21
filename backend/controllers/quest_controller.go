package controllers

import (
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"

	"github.com/gin-gonic/gin"
)

func GetQuests(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var userQuests []models.UserQuest
	// Preload Quest details
	config.DB.Where("user_id = ?", userID).Preload("Quest").Find(&userQuests)

	// If no quests for user, initialize them from general Quest table
	if len(userQuests) == 0 {
		var allQuests []models.Quest
		config.DB.Find(&allQuests)

		for _, q := range allQuests {
			uq := models.UserQuest{
				UserID:  userID,
				QuestID: q.ID,
				Quest:   q,
			}
			config.DB.Create(&uq)
			userQuests = append(userQuests, uq)
		}
	}

	c.JSON(http.StatusOK, userQuests)
}

func ClaimQuest(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	questID := c.Param("id")

	var userQuest models.UserQuest
	if err := config.DB.Where("user_id = ? AND quest_id = ?", userID, questID).First(&userQuest).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Quest not found for this user"})
		return
	}

	if userQuest.IsCompleted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Quest already completed"})
		return
	}

	// Double check progress
	var quest models.Quest
	config.DB.First(&quest, userQuest.QuestID)
	if userQuest.Progress < quest.TargetCount {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Quest progress incomplete"})
		return
	}

	userQuest.IsCompleted = true
	config.DB.Save(&userQuest)

	// Logic for adding points could go here (to a user.Points field if we add it)

	c.JSON(http.StatusOK, gin.H{"message": "Quest claimed successfully", "points": quest.Points})
}
