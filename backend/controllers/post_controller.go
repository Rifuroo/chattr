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
	"gorm.io/gorm"
)

func GetPosts(c *gin.Context) {
	var posts []models.Post
	if err := config.DB.Preload("User").
		Preload("Media").
		Preload("OriginalPost").
		Preload("OriginalPost.User").
		Preload("OriginalPost.Media").
		Preload("Likes").
		Preload("Comments", "parent_id IS NULL").
		Preload("Comments.User").
		Preload("Comments.Likes").
		Preload("Comments.Replies").
		Preload("Comments.Replies.User").
		Preload("Poll").
		Preload("Poll.Votes").
		Where("is_flash = ? OR expires_at > ?", false, time.Now()).
		Order("created_at desc").Find(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch posts"})
		return
	}

	c.JSON(http.StatusOK, posts)
}

func CreatePost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	content := c.PostForm("content")
	spotifyTrackID := c.PostForm("spotify_track_id")

	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
		return
	}

	files := form.File["media"]
	if len(files) == 0 {
		files = form.File["image"]
	}

	post := models.Post{
		UserID:         userID,
		Content:        content,
		SpotifyTrackID: spotifyTrackID,
		CreatedAt:      time.Now(),
	}

	isFlash := c.PostForm("is_flash") == "true"
	expiresInStr := c.PostForm("expires_in") // hours
	if isFlash && expiresInStr != "" {
		expiresIn, _ := strconv.Atoi(expiresInStr)
		expiration := time.Now().Add(time.Duration(expiresIn) * time.Hour)
		post.IsFlash = true
		post.ExpiresAt = &expiration
	}

	if err := config.DB.Create(&post).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}

	var firstImagePath string
	for _, file := range files {
		extension := filepath.Ext(file.Filename)
		newFileName := uuid.New().String() + extension
		savePath := "uploads/" + newFileName

		if err := c.SaveUploadedFile(file, savePath); err != nil {
			continue
		}

		mediaType := "image"
		if extension == ".mp4" || extension == ".mov" || extension == ".avi" {
			mediaType = "video"
		}

		media := models.PostMedia{
			PostID:    post.ID,
			Path:      "/" + savePath,
			Type:      mediaType,
			CreatedAt: time.Now(),
		}
		config.DB.Create(&media)

		if firstImagePath == "" {
			firstImagePath = "/" + savePath
		}
	}

	if firstImagePath != "" {
		config.DB.Model(&post).Update("image_path", firstImagePath)
	}

	pollQuestion := c.PostForm("poll_question")
	pollOptionsRaw := c.PostForm("poll_options") // Assume comma separated or JSON
	isCollaborative := c.PostForm("is_collaborative") == "true"
	if pollQuestion != "" && pollOptionsRaw != "" {
		poll := models.Poll{
			PostID:          post.ID,
			Question:        pollQuestion,
			IsCollaborative: isCollaborative,
			ExpiresAt:       time.Now().Add(24 * time.Hour),
		}
		config.DB.Create(&poll)

		options := services.ParseOptions(pollOptionsRaw)
		for _, optText := range options {
			opt := models.PollOption{
				PollID:      poll.ID,
				Option:      optText,
				CreatedByID: userID,
			}
			config.DB.Create(&opt)
		}
	}

	services.HandleMentions(content, userID, "a post")
	config.DB.Preload("User").Preload("Media").First(&post, post.ID)

	services.Hub.Broadcast(services.ChattrEvent{
		Type:      "post",
		Title:     "New Post!",
		Body:      post.User.Username + " shared something new",
		Username:  post.User.Username,
		Avatar:    post.User.Avatar,
		CreatedAt: post.CreatedAt.Format(time.RFC3339),
	})

	services.UpdateQuestProgress(userID, "post")

	c.JSON(http.StatusCreated, post)
}

func Repost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postID := c.Param("id")

	var originalPost models.Post
	if err := config.DB.First(&originalPost, postID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Original post not found"})
		return
	}

	var input struct {
		Content string `json:"content"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		input.Content = c.PostForm("content")
	}

	repost := models.Post{
		UserID:         userID,
		Content:        input.Content,
		OriginalPostID: &originalPost.ID,
		CreatedAt:      time.Now(),
	}

	config.DB.Create(&repost)

	var sender models.User
	config.DB.First(&sender, userID)
	services.CreateNotification(originalPost.UserID, "repost", "New Repost", sender.Username+" shared your post!")

	config.DB.Preload("User").Preload("Media").Preload("OriginalPost").Preload("OriginalPost.User").Preload("OriginalPost.Media").First(&repost, repost.ID)
	c.JSON(http.StatusOK, repost)
}

func DeletePost(c *gin.Context) {
	postID := c.Param("id")
	userID := c.MustGet("userID").(uint)

	var post models.Post
	if err := config.DB.First(&post, postID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	if post.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized"})
		return
	}

	config.DB.Where("post_id = ?", postID).Delete(&models.Like{})
	config.DB.Where("post_id = ?", postID).Delete(&models.PostMedia{})
	config.DB.Where("post_id = ?", postID).Delete(&models.Comment{})

	var poll models.Poll
	if err := config.DB.Where("post_id = ?", postID).First(&poll).Error; err == nil {
		config.DB.Where("poll_id = ?", poll.ID).Delete(&models.PollVote{})
		config.DB.Delete(&poll)
	}

	config.DB.Delete(&post)
	c.JSON(http.StatusOK, gin.H{"message": "Post deleted"})
}

func VotePoll(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postID := c.Param("id")

	var input struct {
		OptionIndex int `json:"option_index"`
	}
	c.ShouldBindJSON(&input)

	var poll models.Poll
	if err := config.DB.Where("post_id = ?", postID).First(&poll).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Poll not found"})
		return
	}

	var existingVote models.PollVote
	if config.DB.Where("poll_id = ? AND user_id = ?", poll.ID, userID).First(&existingVote).Error == nil {
		existingVote.OptionIndex = input.OptionIndex
		config.DB.Save(&existingVote)
	} else {
		config.DB.Create(&models.PollVote{PollID: poll.ID, UserID: userID, OptionIndex: input.OptionIndex})
	}

	c.JSON(http.StatusOK, gin.H{"message": "Vote recorded"})
}

func GetExploreFeed(c *gin.Context) {
	var posts []models.Post
	config.DB.Preload("User").Preload("Media").Preload("Poll").Preload("Poll.Options").Preload("Poll.Votes").
		Where("is_flash = ? OR expires_at > ?", false, time.Now()).
		Order("created_at DESC").Limit(50).Find(&posts)
	c.JSON(http.StatusOK, posts)
}

func ToggleSavePost(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postID, _ := strconv.Atoi(c.Param("id"))

	var saved models.SavedPost
	if config.DB.Where("user_id = ? AND post_id = ?", userID, postID).First(&saved).Error == nil {
		config.DB.Delete(&saved)
		c.JSON(http.StatusOK, gin.H{"saved": false})
	} else {
		config.DB.Create(&models.SavedPost{UserID: userID, PostID: uint(postID)})
		c.JSON(http.StatusOK, gin.H{"saved": true})
	}
}

func GetSavedPosts(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var savedPosts []models.SavedPost
	config.DB.Where("user_id = ?", userID).Preload("Post").Preload("Post.User").Preload("Post.Media").Find(&savedPosts)
	c.JSON(http.StatusOK, savedPosts)
}

func GetPostsByHashtag(c *gin.Context) {
	tag := c.Param("tag")
	var posts []models.Post
	config.DB.Preload("User").Preload("Media").Where("content LIKE ?", "%#"+tag+"%").Order("created_at DESC").Find(&posts)
	c.JSON(http.StatusOK, posts)
}

func ViewPost(c *gin.Context) {
	postID := c.Param("id")
	config.DB.Model(&models.Post{}).Where("id = ?", postID).UpdateColumn("view_count", gorm.Expr("view_count + ?", 1))
	c.JSON(http.StatusOK, gin.H{"message": "View count updated"})
}

func AddPollOption(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postID := c.Param("id")
	optionText := c.PostForm("option")

	if optionText == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Option text is required"})
		return
	}

	var poll models.Poll
	if err := config.DB.Where("post_id = ?", postID).First(&poll).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Poll not found"})
		return
	}

	if !poll.IsCollaborative {
		c.JSON(http.StatusForbidden, gin.H{"error": "This poll is not collaborative"})
		return
	}

	opt := models.PollOption{
		PollID:      poll.ID,
		Option:      optionText,
		CreatedByID: userID,
	}

	if err := config.DB.Create(&opt).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add option"})
		return
	}

	c.JSON(http.StatusCreated, opt)
}
