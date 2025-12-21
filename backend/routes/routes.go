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

		// Chattr Flash WebSocket
		api.GET("/ws/flash", controllers.FlashWebSocket)

		// Profile & Follow
		users := api.Group("/users")
		{
			users.GET("/memory-lane", controllers.GetMemoryLane)
			users.GET("/:id", controllers.GetUserProfile)
			users.PUT("/profile", controllers.UpdateProfile)
			users.GET("/:id/followers", controllers.GetFollowers)
			users.GET("/:id/following", controllers.GetFollowing)
			users.POST("/:id/follow", controllers.FollowUser)
			users.DELETE("/:id/unfollow", controllers.UnfollowUser)
			users.POST("/fcm-token", controllers.UpdateFCMToken)

			// Privacy & Requests
			users.GET("/requests", controllers.GetFollowRequests)
			users.POST("/requests/:id/respond", controllers.RespondToFollowRequest)
			users.POST("/:id/block", controllers.ToggleBlock)
			users.POST("/ghost-mode", controllers.ToggleGhostMode)
		}

		// Settings
		api.PUT("/settings/privacy", controllers.UpdateProfile)

		// Posts
		posts := api.Group("/posts")
		{
			posts.POST("", controllers.CreatePost)
			posts.GET("", controllers.GetPosts)
			posts.DELETE("/:id", controllers.DeletePost)
			posts.POST("/:id/like", controllers.LikePost)
			posts.POST("/:id/comment", controllers.CommentPost)
			posts.POST("/:id/repost", controllers.Repost)
			posts.GET("/explore", controllers.GetExploreFeed)
			posts.POST("/:id/save", controllers.ToggleSavePost)
			posts.POST("/:id/vote", controllers.VotePoll)
			posts.POST("/:id/poll/options", controllers.AddPollOption)
			posts.GET("/hashtag/:tag", controllers.GetPostsByHashtag)
			posts.POST("/:id/view", controllers.ViewPost)
		}

		api.GET("/users/saved", controllers.GetSavedPosts)

		// Reels
		reels := api.Group("/reels")
		{
			reels.POST("", controllers.CreateReel)
			reels.GET("", controllers.GetReels)
		}

		// Stories (Individual)
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

		// Anonymous Tells
		api.POST("/users/:id/tell", controllers.SendTell)
		api.GET("/tells", controllers.GetMyTells)
		api.PUT("/tells/:id/read", controllers.MarkTellAsRead)

		api.POST("/shared-stories/:id/join", controllers.JoinSharedStory)

		// Highlights (Phase 9)
		highlights := api.Group("/highlights")
		{
			highlights.POST("", controllers.CreateHighlight)
			highlights.GET("/user/:userId", controllers.GetHighlights)
			highlights.POST("/:id/members", controllers.AddHighlightMember)
			highlights.POST("/:id/items", controllers.AddHighlightItem)
		}

		// Spotify
		api.GET("/spotify/search", controllers.SearchSpotify)

		// Phase 7: Community & Gamification
		quests := api.Group("/quests")
		{
			quests.GET("", controllers.GetQuests)
			quests.POST("/:id/claim", controllers.ClaimQuest)
		}

		api.GET("/roulette/match", controllers.RouletteMatch)

		// AI Features
		api.POST("/ai/generate-caption", controllers.GenerateAICaption)

		// Webhook (Optional/Stub)
		api.POST("/webhook", controllers.Webhook)
	}
}
