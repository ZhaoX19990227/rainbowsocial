package ws

import (
	"encoding/json"
	"log"
	"sync"

	"rainbow-social-backend/internal/model"
)

type PresenceUpdater interface {
	SetOnlineStatus(userID int64, online bool) error
}

type Hub struct {
	clients    map[int64]map[*Client]bool
	register   chan *Client
	unregister chan *Client
	direct     chan model.ChatMessage
	reads      chan model.ConversationReadEvent
	presence   PresenceUpdater
	mu         sync.RWMutex
}

func NewHub(presence PresenceUpdater) *Hub {
	return &Hub{
		clients:    make(map[int64]map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		direct:     make(chan model.ChatMessage),
		reads:      make(chan model.ConversationReadEvent),
		presence:   presence,
	}
}

func (h *Hub) RegisterClient(client *Client) {
	h.register <- client
}

func (h *Hub) UnregisterClient(client *Client) {
	h.unregister <- client
}

func (h *Hub) SendDirect(message model.ChatMessage) {
	h.direct <- message
}

func (h *Hub) SendConversationRead(event model.ConversationReadEvent) {
	h.reads <- event
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if _, ok := h.clients[client.UserID]; !ok {
				h.clients[client.UserID] = make(map[*Client]bool)
			}
			h.clients[client.UserID][client] = true
			h.mu.Unlock()
			if err := h.presence.SetOnlineStatus(client.UserID, true); err != nil {
				log.Printf("set online status: %v", err)
			}
		case client := <-h.unregister:
			h.mu.Lock()
			if userClients, ok := h.clients[client.UserID]; ok {
				if _, found := userClients[client]; found {
					delete(userClients, client)
					close(client.Send)
				}
				if len(userClients) == 0 {
					delete(h.clients, client.UserID)
					if err := h.presence.SetOnlineStatus(client.UserID, false); err != nil {
						log.Printf("set offline status: %v", err)
					}
				}
			}
			h.mu.Unlock()
		case message := <-h.direct:
			payload, err := json.Marshal(ginMessageEnvelope{
				Event: "message",
				Data:  message,
			})
			if err != nil {
				log.Printf("marshal ws message: %v", err)
				continue
			}
			h.dispatch(message.ToUser, payload)
			h.dispatch(message.FromUser, payload)
		case event := <-h.reads:
			payload, err := json.Marshal(struct {
				Event string                      `json:"event"`
				Data  model.ConversationReadEvent `json:"data"`
			}{
				Event: "conversation_read",
				Data:  event,
			})
			if err != nil {
				log.Printf("marshal ws read event: %v", err)
				continue
			}
			h.dispatch(event.UserID, payload)
			h.dispatch(event.PeerUserID, payload)
		}
	}
}

func (h *Hub) dispatch(userID int64, payload []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for client := range h.clients[userID] {
		select {
		case client.Send <- payload:
		default:
			go h.UnregisterClient(client)
		}
	}
}

func websocketErrorPayload(payload messageErrorEnvelope) ([]byte, error) {
	return json.Marshal(struct {
		Event string               `json:"event"`
		Data  messageErrorEnvelope `json:"data"`
	}{
		Event: "message_error",
		Data:  payload,
	})
}

type ginMessageEnvelope struct {
	Event string            `json:"event"`
	Data  model.ChatMessage `json:"data"`
}
