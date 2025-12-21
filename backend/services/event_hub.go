package services

import (
	"encoding/json"
	"fmt"
	"sync"

	"github.com/gorilla/websocket"
)

// ChattrEvent represents a global activity event
type ChattrEvent struct {
	Type      string `json:"type"` // "post", "follow", "trend"
	Title     string `json:"title"`
	Body      string `json:"body"`
	Username  string `json:"username"`
	Avatar    string `json:"avatar"`
	CreatedAt string `json:"created_at"`
}

type EventHub struct {
	clients    map[*websocket.Conn]bool
	broadcast  chan ChattrEvent
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
	mu         sync.Mutex
}

var Hub = EventHub{
	clients:    make(map[*websocket.Conn]bool),
	broadcast:  make(chan ChattrEvent),
	register:   make(chan *websocket.Conn),
	unregister: make(chan *websocket.Conn),
}

func (h *EventHub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			fmt.Println("New client connected to Flash")

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				client.Close()
			}
			h.mu.Unlock()
			fmt.Println("Client disconnected from Flash")

		case event := <-h.broadcast:
			h.mu.Lock()
			msg, _ := json.Marshal(event)
			for client := range h.clients {
				err := client.WriteMessage(websocket.TextMessage, msg)
				if err != nil {
					fmt.Printf("Websocket WriteMessage error: %v\n", err)
					client.Close()
					delete(h.clients, client)
				}
			}
			h.mu.Unlock()
		}
	}
}

func (h *EventHub) Broadcast(event ChattrEvent) {
	h.broadcast <- event
}
