package ws

import (
	"log"
	"time"

	"github.com/gorilla/websocket"

	"rainbow-social-backend/internal/service"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 4096
)

type inboundMessage struct {
	ClientMessageID string `json:"client_message_id"`
	ToUser          int64  `json:"to_user"`
	Content         string `json:"content"`
	Type            string `json:"type"`
	MediaURL        string `json:"media_url"`
	DurationSeconds int    `json:"duration_seconds"`
}

type messageErrorEnvelope struct {
	ClientMessageID string `json:"client_message_id,omitempty"`
	Error           string `json:"error"`
}

type Client struct {
	Hub         *Hub
	Conn        *websocket.Conn
	Send        chan []byte
	UserID      int64
	ChatService *service.ChatService
}

func NewClient(hub *Hub, conn *websocket.Conn, userID int64, chatService *service.ChatService) *Client {
	return &Client{
		Hub:         hub,
		Conn:        conn,
		Send:        make(chan []byte, 256),
		UserID:      userID,
		ChatService: chatService,
	}
}

func (c *Client) ReadPump() {
	defer func() {
		c.Hub.UnregisterClient(c)
		_ = c.Conn.Close()
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	_ = c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		return c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	})

	for {
		var inbound inboundMessage
		if err := c.Conn.ReadJSON(&inbound); err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("ws read error: %v", err)
			}
			break
		}

		message, err := c.ChatService.SaveMessage(
			c.UserID,
			inbound.ToUser,
			inbound.Content,
			inbound.Type,
			inbound.ClientMessageID,
			inbound.MediaURL,
			inbound.DurationSeconds,
		)
		if err != nil {
			log.Printf("save message: %v", err)
			c.enqueueError(messageErrorEnvelope{
				ClientMessageID: inbound.ClientMessageID,
				Error:           err.Error(),
			})
			continue
		}
		c.Hub.SendDirect(*message)
	}
}

func (c *Client) enqueueError(payload messageErrorEnvelope) {
	data, err := websocketErrorPayload(payload)
	if err != nil {
		log.Printf("marshal ws error: %v", err)
		return
	}

	select {
	case c.Send <- data:
	default:
		go c.Hub.UnregisterClient(c)
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		_ = c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
