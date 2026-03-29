package api

import (
	"fmt"
	"log"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/config"
	"rainbow-social-backend/internal/storage"
)

type UploadHandler struct {
	cfg       *config.Config
	fileStore storage.FileStore
}

func NewUploadHandler(cfg *config.Config) *UploadHandler {
	return &UploadHandler{
		cfg:       cfg,
		fileStore: storage.NewFileStore(cfg),
	}
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

	extension := strings.ToLower(filepath.Ext(file.Filename))
	if extension == "" {
		extension = fallbackExtension
	}
	if _, ok := allowedExtensions[extension]; !ok {
		failure(c, http.StatusBadRequest, "unsupported file type")
		return
	}
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), extension)

	url, err := h.fileStore.Save(c.Request.Context(), file, filename)
	if err != nil {
		log.Printf("upload file failed: %v", err)
		failure(c, http.StatusInternalServerError, err.Error())
		return
	}

	success(c, gin.H{
		"url": url,
	})
}
