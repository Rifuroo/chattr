package controllers

import (
	"fmt"
	"net/http"
	"social-media-backend/config"
	"social-media-backend/models"

	"github.com/gin-gonic/gin"
)

func CreateReel(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	caption := c.PostForm("caption")

	file, err := c.FormFile("video")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Video is required"})
		return
	}

	filename := fmt.Sprintf("reel_%d_%s", userID, file.Filename)
	c.SaveUploadedFile(file, "uploads/"+filename)

	reel := models.Reel{
		UserID:    userID,
		VideoPath: "/uploads/" + filename,
		Caption:   caption,
	}

	if err := config.DB.Create(&reel).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create reel"})
		return
	}

	c.JSON(http.StatusCreated, reel)
}

func GetReels(c *gin.Context) {
	var reels []models.Reel
	config.DB.Preload("User").Order("created_at desc").Find(&reels)
	c.JSON(http.StatusOK, reels)
}
