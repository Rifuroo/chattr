package controllers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func Webhook(c *gin.Context) {
	var body interface{}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON body"})
		return
	}

	// Simple log and success response
	c.JSON(http.StatusOK, gin.H{
		"message": "Webhook received successfully",
		"received_data": body,
	})
}
