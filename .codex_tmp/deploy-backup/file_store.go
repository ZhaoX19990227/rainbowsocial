package storage

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"

	"rainbow-social-backend/internal/config"
)

type FileStore interface {
	Save(ctx context.Context, file *multipart.FileHeader, filename string) (string, error)
}

func NewFileStore(cfg *config.Config) FileStore {
	if cfg.RemoteUploadEnabled {
		return &remoteFileStore{cfg: cfg}
	}
	return &localFileStore{cfg: cfg}
}

type localFileStore struct {
	cfg *config.Config
}

func (s *localFileStore) Save(_ context.Context, file *multipart.FileHeader, filename string) (string, error) {
	if err := os.MkdirAll(s.cfg.UploadDir, 0o755); err != nil {
		return "", err
	}

	src, err := file.Open()
	if err != nil {
		return "", err
	}
	defer src.Close()

	targetPath := filepath.Join(s.cfg.UploadDir, filename)
	dst, err := os.Create(targetPath)
	if err != nil {
		return "", err
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		return "", err
	}

	return buildPublicUploadURL(s.cfg, filename), nil
}

type remoteFileStore struct {
	cfg *config.Config
}

func (s *remoteFileStore) Save(ctx context.Context, file *multipart.FileHeader, filename string) (string, error) {
	if strings.TrimSpace(s.cfg.RemoteUploadHost) == "" ||
		strings.TrimSpace(s.cfg.RemoteUploadUser) == "" ||
		strings.TrimSpace(s.cfg.RemoteUploadPassword) == "" ||
		strings.TrimSpace(s.cfg.RemoteUploadDir) == "" {
		return "", fmt.Errorf("remote upload is enabled but remote upload config is incomplete")
	}

	src, err := file.Open()
	if err != nil {
		return "", err
	}
	defer src.Close()

	address := fmt.Sprintf("%s:%d", s.cfg.RemoteUploadHost, s.cfg.RemoteUploadPort)
	sshClient, err := ssh.Dial("tcp", address, &ssh.ClientConfig{
		User: s.cfg.RemoteUploadUser,
		Auth: []ssh.AuthMethod{
			ssh.Password(s.cfg.RemoteUploadPassword),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	})
	if err != nil {
		return "", err
	}
	defer sshClient.Close()

	sftpClient, err := sftp.NewClient(sshClient)
	if err != nil {
		return "", err
	}
	defer sftpClient.Close()

	select {
	case <-ctx.Done():
		return "", ctx.Err()
	default:
	}

	if err := sftpClient.MkdirAll(s.cfg.RemoteUploadDir); err != nil {
		return "", err
	}

	remotePath := path.Join(s.cfg.RemoteUploadDir, filename)
	dst, err := sftpClient.Create(remotePath)
	if err != nil {
		return "", err
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		return "", err
	}

	return buildPublicUploadURL(s.cfg, filename), nil
}

func buildPublicUploadURL(cfg *config.Config, filename string) string {
	baseURL := strings.TrimRight(strings.TrimSpace(cfg.PublicBaseURL), "/")
	if baseURL == "" && strings.TrimSpace(cfg.RemoteUploadHost) != "" {
		baseURL = "http://" + strings.TrimRight(strings.TrimSpace(cfg.RemoteUploadHost), "/")
	}
	if baseURL == "" {
		return "/uploads/" + filename
	}
	return baseURL + "/uploads/" + filename
}
