package api

import "github.com/gin-gonic/gin"

func success(c *gin.Context, data any) {
	c.JSON(200, gin.H{
		"success": true,
		"data":    data,
	})
}

func failure(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{
		"success": false,
		"error":   message,
	})
}
