package api

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/config"
)

type UploadHandler struct {
	cfg *config.Config
}

func NewUploadHandler(cfg *config.Config) *UploadHandler {
	return &UploadHandler{cfg: cfg}
}

func (h *UploadHandler) UploadImage(c *gin.Context) {
	h.uploadFile(c, 8*1024*1024, map[string]struct{}{
		".jpg":  {},
		".jpeg": {},
		".png":  {},
		".webp": {},
		".heic": {},
	}, ".jpg")
}

func (h *UploadHandler) UploadAudio(c *gin.Context) {
	h.uploadFile(c, 16*1024*1024, map[string]struct{}{
		".m4a": {},
		".aac": {},
		".mp3": {},
		".wav": {},
	}, ".m4a")
}

func (h *UploadHandler) uploadFile(c *gin.Context, maxSize int64, allowedExtensions map[string]struct{}, fallbackExtension string) {
	file, err := c.FormFile("file")
	if err != nil {
		failure(c, http.StatusBadRequest, "file is required")
		return
	}

	if file.Size > maxSize {
		failure(c, http.StatusBadRequest, fmt.Sprintf("file must be smaller than %dMB", maxSize/(1024*1024)))
		return
	}

	if err := os.MkdirAll(h.cfg.UploadDir, 0o755); err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}

	extension := strings.ToLower(filepath.Ext(file.Filename))
	if extension == "" {
		extension = fallbackExtension
	}
	if _, ok := allowedExtensions[extension]; !ok {
		failure(c, http.StatusBadRequest, "unsupported file type")
		return
	}
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), extension)
	targetPath := filepath.Join(h.cfg.UploadDir, filename)

	if err := c.SaveUploadedFile(file, targetPath); err != nil {
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}

	success(c, gin.H{
		"url": fmt.Sprintf("/uploads/%s", filename),
	})
}
