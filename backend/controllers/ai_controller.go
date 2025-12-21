package controllers

import (
	"net/http"
	"social-media-backend/services"

	"github.com/gin-gonic/gin"
)

func GenerateAICaption(c *gin.Context) {
	var input struct {
		Prompt string `json:"prompt"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		input.Prompt = c.PostForm("prompt")
	}

	if input.Prompt == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Prompt is required"})
		return
	}

	caption, err := services.GenerateCaption(input.Prompt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate caption", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"caption": caption})
}
