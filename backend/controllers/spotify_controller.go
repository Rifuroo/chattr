package controllers

import (
	"net/http"
	"social-media-backend/services"

	"github.com/gin-gonic/gin"
)

func SearchSpotify(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query is required"})
		return
	}

	tracks, err := services.SearchSpotifyTracks(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tracks)
}
