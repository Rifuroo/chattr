package main

import (
	"os"
	"social-media-backend/config"
	"social-media-backend/models"
	"social-media-backend/routes"

	cors "github.com/rs/cors/wrapper/gin"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize database
	config.ConnectDatabase()

	// Auto Migration
	config.DB.AutoMigrate(
		&models.User{},
		&models.Follow{},
		&models.Post{},
		&models.Reel{},
		&models.Story{},
		&models.Like{},
		&models.Comment{},
		&models.CommentLike{},
		&models.Chat{},
		&models.Message{},
		&models.Notification{},
		&models.StoryView{},
	)

	// Initialize Gin
	r := gin.Default()

	// Robust CORS - Use false for AllowCredentials when using wildcard origins
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
		port = "8080"
	}
	r.Run(":" + port)
}
