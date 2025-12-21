package services

import (
	"social-media-backend/config"
	"social-media-backend/models"
)

func UpdateQuestProgress(userID uint, action string) {
	var userQuests []models.UserQuest
	// Find all in-progress quests for this user matching the action
	config.DB.Joins("Quest").
		Where("user_id = ? AND is_completed = false AND Quest.target_action = ?", userID, action).
		Find(&userQuests)

	for _, uq := range userQuests {
		uq.Progress += 1
		config.DB.Save(&uq)
	}
}
