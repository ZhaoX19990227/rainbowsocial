package email

import (
	"crypto/tls"
	"fmt"
	"log"
	"net"
	"net/smtp"

	"rainbow-social-backend/internal/config"
)

type Sender interface {
	SendOTP(toEmail, code string) error
}

type SMTPEmailSender struct {
	cfg *config.Config
}

func NewSMTPEmailSender(cfg *config.Config) *SMTPEmailSender {
	return &SMTPEmailSender{cfg: cfg}
}

func (s *SMTPEmailSender) SendOTP(toEmail, code string) error {
	if !s.cfg.SMTPEnabled {
		log.Printf("[DEV OTP] email=%s code=%s", toEmail, code)
		return nil
	}

	if s.cfg.SMTPUsername == "" || s.cfg.SMTPPassword == "" || s.cfg.SMTPHost == "" {
		return fmt.Errorf("smtp credentials are incomplete")
	}

	subject := "Your login verification code"
	body := fmt.Sprintf("Your verification code is %s. It expires in %d minutes.", code, s.cfg.OTPExpiryMinutes)
	message := []byte("To: " + toEmail + "\r\n" +
		"From: " + s.cfg.SMTPFrom + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/plain; charset=UTF-8\r\n\r\n" +
		body + "\r\n")

	auth := smtp.PlainAuth("", s.cfg.SMTPUsername, s.cfg.SMTPPassword, s.cfg.SMTPHost)
	addr := fmt.Sprintf("%s:%d", s.cfg.SMTPHost, s.cfg.SMTPPort)

	if s.cfg.SMTPPort == 465 {
		return s.sendWithTLS(addr, toEmail, message)
	}

	return smtp.SendMail(addr, auth, s.cfg.SMTPFrom, []string{toEmail}, message)
}

func (s *SMTPEmailSender) sendWithTLS(addr string, toEmail string, message []byte) error {
	conn, err := tls.Dial("tcp", addr, &tls.Config{
		ServerName: s.cfg.SMTPHost,
	})
	if err != nil {
		return err
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, s.cfg.SMTPHost)
	if err != nil {
		return err
	}
	defer client.Close()

	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		return err
	}

	if err := client.Auth(smtp.PlainAuth("", s.cfg.SMTPUsername, s.cfg.SMTPPassword, host)); err != nil {
		return err
	}
	if err := client.Mail(s.cfg.SMTPFrom); err != nil {
		return err
	}
	if err := client.Rcpt(toEmail); err != nil {
		return err
	}

	writer, err := client.Data()
	if err != nil {
		return err
	}
	if _, err := writer.Write(message); err != nil {
		return err
	}
	if err := writer.Close(); err != nil {
		return err
	}

	return client.Quit()
}
