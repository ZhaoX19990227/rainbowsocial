package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/pkg/utils"
)

const userIDContextKey = "userID"

func Auth(jwtManager *utils.JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := strings.TrimSpace(c.GetHeader("Authorization"))
		if !strings.HasPrefix(authHeader, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing bearer token"})
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		claims, err := jwtManager.ParseToken(token)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}

		c.Set(userIDContextKey, claims.UserID)
		c.Next()
	}
}

func GetUserID(c *gin.Context) int64 {
	value, exists := c.Get(userIDContextKey)
	if !exists {
		return 0
	}
	userID, ok := value.(int64)
	if !ok {
		return 0
	}
	return userID
}
