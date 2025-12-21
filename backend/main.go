package main

import (
	"os"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/routes"
	"social-media-backend/services"

	cors "github.com/rs/cors/wrapper/gin"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize database
	config.ConnectDatabase()

	// Start Global Event Hub (Chattr Flash)
	go services.Hub.Run()

	// Auto Migration
	config.DB.AutoMigrate(
		&models.User{},
		&models.Follow{},
		&models.Post{},
		&models.PostMedia{},
		&models.Like{},
		&models.Comment{},
		&models.CommentLike{},
		&models.Chat{},
		&models.Message{},
		&models.Notification{},
		&models.Reel{},
		&models.Story{},
		&models.StoryView{},
		&models.SavedPost{},
		&models.SharedStory{},
		&models.SharedStoryMember{},
		&models.SharedStoryMedia{},
		&models.Poll{},
		&models.PollOption{},
		&models.PollVote{},
		&models.FollowRequest{},
		&models.Block{},
		&models.Tell{},
		&models.Quest{},
		&models.UserQuest{},
		&models.Highlight{},
		&models.HighlightMember{},
		&models.HighlightItem{},
	)

	// Seed Quests if none exist
	var questCount int64
	config.DB.Model(&models.Quest{}).Count(&questCount)
	if questCount == 0 {
		quests := []models.Quest{
			{Title: "Daily Poster", Description: "Share what's on your mind today.", Points: 50, TargetAction: "post", TargetCount: 1},
			{Title: "Supportive Friend", Description: "Like 5 posts from others.", Points: 30, TargetAction: "like", TargetCount: 5},
			{Title: "Story Teller", Description: "Post a story for your friends.", Points: 40, TargetAction: "story", TargetCount: 1},
			{Title: "Conversationalist", Description: "Comment on 3 different posts.", Points: 45, TargetAction: "comment", TargetCount: 3},
		}
		for _, q := range quests {
			config.DB.Create(&q)
		}
	}

	// Initialize Gin
	r := gin.Default()

	// Robust CORS
	r.Use(cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposedHeaders:   []string{"Content-Length"},
		AllowCredentials: false,
	}))

	// Serve static files for uploads
	r.Static("/uploads", "./uploads")

	// Setup routes
	routes.SetupRoutes(r)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}
	r.Run(":" + port)
}
