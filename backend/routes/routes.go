package routes

import (
	"social-media-backend/controllers"
	"social-media-backend/middlewares"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	// Auth routes
	auth := r.Group("/auth")
	{
		auth.POST("/register", controllers.Register)
		auth.POST("/login", controllers.Login)
	}

	// Protected routes
	api := r.Group("/")
	api.Use(middlewares.AuthMiddleware())
	{
		// Search
		api.GET("/search/users", controllers.SearchUsers)

		// Profile & Follow
		users := api.Group("/users")
		{
			users.GET("/:id", controllers.GetUserProfile)
			users.PUT("/profile", controllers.UpdateProfile)
			users.POST("/:id/follow", controllers.FollowUser)
			users.DELETE("/:id/unfollow", controllers.UnfollowUser)
			users.POST("/fcm-token", controllers.UpdateFCMToken)
		}

		// Settings
		api.PUT("/settings/privacy", controllers.UpdateProfile) // Reusing UpdateProfile for simplicity

		// Posts
		posts := api.Group("/posts")
		{
			posts.POST("", controllers.CreatePost)
			posts.GET("", controllers.GetPosts)
			posts.POST("/:id/like", controllers.LikePost)
			posts.POST("/:id/comment", controllers.CommentPost)
		}

		// Reels
		reels := api.Group("/reels")
		{
			reels.POST("", controllers.CreateReel)
			reels.GET("", controllers.GetReels)
		}

		// Stories
		stories := api.Group("/stories")
		{
			stories.POST("", controllers.CreateStory)
			stories.GET("", controllers.GetStories)
			stories.POST("/:id/view", controllers.ViewStory)
		}

		// DM (Chats)
		chats := api.Group("/chats")
		{
			chats.POST("/start", controllers.StartChat)
			chats.GET("", controllers.GetChats)
			chats.GET("/:id/messages", controllers.GetMessages)
			chats.POST("/:id/messages", controllers.SendMessage)
			chats.POST("/:id/read", controllers.MarkMessagesAsRead)
			chats.PUT("/messages/:messageId", controllers.UpdateMessage)
			chats.DELETE("/messages/:messageId", controllers.DeleteMessage)
		}

		notifications := api.Group("/notifications")
		{
			notifications.GET("", controllers.GetNotifications)
			notifications.PUT("/:id/read", controllers.MarkNotificationAsRead)
		}

		// Comments
		api.POST("/comments/:id/like", controllers.LikeComment)

		// Webhook (Optional/Stub)
		api.POST("/webhook", controllers.Webhook)
	}
}
