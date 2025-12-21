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

func LikePost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postIDStr := c.Param("id")
	postID, _ := strconv.Atoi(postIDStr)

	var likes []models.Like
	config.DB.Where("user_id = ? AND post_id = ?", userID, postID).Limit(1).Find(&likes)

	if len(likes) > 0 {
		// Unlike
		config.DB.Delete(&likes[0])
		c.JSON(http.StatusOK, gin.H{"message": "Post unliked"})
	} else {
		// Like
		newLike := models.Like{
			UserID: userID,
			PostID: uint(postID),
		}
		config.DB.Create(&newLike)

		// Notification
		var post models.Post
		var user models.User
		config.DB.First(&user, userID)
		config.DB.Preload("User").First(&post, postID)
		if post.UserID != userID {
			title := "New Like"
			body := user.Username + " liked your post!"
			services.CreateNotification(post.UserID, "like", title, body)
			if post.User.FCMToken != "" {
				services.SendFCMNotification(post.User.FCMToken, title, body, map[string]string{
					"type":    "like",
					"post_id": strconv.Itoa(int(post.ID)),
				})
			}
		}

		c.JSON(http.StatusOK, gin.H{"message": "Post liked"})
	}
}

func CommentPost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postIDStr := c.Param("id")
	postID, _ := strconv.Atoi(postIDStr)

	var input struct {
		Content  string `json:"content" binding:"required"`
		ParentID *uint  `json:"parent_id"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	comment := models.Comment{
		UserID:    userID,
		PostID:    uint(postID),
		ParentID:  input.ParentID,
		Content:   input.Content,
		CreatedAt: time.Now(),
	}

	if err := config.DB.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add comment"})
		return
	}

	// Notification
	var sender models.User
	config.DB.First(&sender, userID)

	if comment.ParentID != nil {
		// Reply notification
		var parentComment models.Comment
		config.DB.Preload("User").First(&parentComment, *comment.ParentID)
		if parentComment.UserID != userID {
			title := "New Reply"
			body := sender.Username + " replied to your comment!"
			services.CreateNotification(parentComment.UserID, "reply", title, body)
			if parentComment.User.FCMToken != "" {
				services.SendFCMNotification(parentComment.User.FCMToken, title, body, map[string]string{
					"type":       "reply",
					"post_id":    strconv.Itoa(int(postID)),
					"comment_id": strconv.Itoa(int(comment.ID)),
				})
			}
		}
	} else {
		// Top-level comment notification
		var post models.Post
		config.DB.Preload("User").First(&post, postID)
		if post.UserID != userID {
			title := "New Comment"
			body := sender.Username + " commented on your post!"
			services.CreateNotification(post.UserID, "comment", title, body)
			if post.User.FCMToken != "" {
				services.SendFCMNotification(post.User.FCMToken, title, body, map[string]string{
					"type":    "comment",
					"post_id": strconv.Itoa(int(post.ID)),
				})
			}
		}
	}

	// Mentions
	services.HandleMentions(input.Content, userID, "a comment")

	config.DB.Preload("User").First(&comment, comment.ID)
	c.JSON(http.StatusCreated, comment)
}

func LikeComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	commentIDStr := c.Param("id")
	commentID, _ := strconv.Atoi(commentIDStr)

	var likes []models.CommentLike
	config.DB.Where("user_id = ? AND comment_id = ?", userID, commentID).First(&likes)

	if len(likes) > 0 {
		config.DB.Delete(&likes[0])
		c.JSON(http.StatusOK, gin.H{"message": "Comment unliked"})
	} else {
		newLike := models.CommentLike{
			UserID:    userID,
			CommentID: uint(commentID),
		}
		config.DB.Create(&newLike)

		// Notification
		var sender models.User
		var comment models.Comment
		config.DB.First(&sender, userID)
		config.DB.Preload("User").First(&comment, commentID)
		if comment.UserID != userID {
			title := "Comment Liked"
			body := sender.Username + " liked your comment!"
			services.CreateNotification(comment.UserID, "like", title, body)
			if comment.User.FCMToken != "" {
				services.SendFCMNotification(comment.User.FCMToken, title, body, map[string]string{
					"type":       "comment_like",
					"post_id":    strconv.Itoa(int(comment.PostID)),
					"comment_id": strconv.Itoa(int(comment.ID)),
				})
			}
		}

		c.JSON(http.StatusOK, gin.H{"message": "Comment liked"})
	}
}
