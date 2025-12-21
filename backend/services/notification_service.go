package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"regexp"
	"social-media-backend/config"
	"social-media-backend/models"
	"strings"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var fcmClient *messaging.Client

func init() {
	ctx := context.Background()

	var data []byte
	var err error

	// Try reading from environment variable first (Cloud/Docker)
	if envData := os.Getenv("FIREBASE_SERVICE_ACCOUNT"); envData != "" {
		data = []byte(envData)
	} else {
		// Fallback to local file (Local Development)
		data, err = os.ReadFile("chattr-84cc5-firebase-adminsdk-fbsvc-e91eddaa13.json")
		if err != nil {
			log.Printf("Firebase warning: service account file not found and FIREBASE_SERVICE_ACCOUNT env var is empty. FCM will be disabled.\n")
			return
		}
	}

	var configMap map[string]interface{}
	if err := json.Unmarshal(data, &configMap); err != nil {
		log.Printf("error unmarshaling firebase config: %v\n", err)
		return
	}

	if pk, ok := configMap["private_key"].(string); ok {
		configMap["private_key"] = strings.ReplaceAll(pk, "\\n", "\n")
	}

	fixedData, _ := json.Marshal(configMap)
	opt := option.WithCredentialsJSON(fixedData)

	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Printf("error initializing firebase app: %v\n", err)
		return
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("error getting Messaging client: %v\n", err)
		return
	}
	fcmClient = client
}

func SendFCMNotification(token string, title string, body string) {
	if fcmClient == nil {
		fmt.Printf("FCM Client not initialized. Stub: %s - %s\n", title, body)
		return
	}

	ctx := context.Background()
	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Token: token,
	}

	response, err := fcmClient.Send(ctx, message)
	if err != nil {
		log.Printf("FCM Error: %v\n", err)
		return
	}
	fmt.Println("Successfully sent message:", response)
}

func CreateNotification(userID uint, notifType, title, body string) {
	notif := models.Notification{
		UserID:    userID,
		Type:      notifType,
		Title:     title,
		Body:      body,
		CreatedAt: time.Now(),
	}
	config.DB.Create(&notif)
}

func HandleMentions(content string, senderID uint, sourceTitle string) {
	re := regexp.MustCompile(`@(\w+)`)
	matches := re.FindAllStringSubmatch(content, -1)

	var sender models.User
	config.DB.First(&sender, senderID)

	for _, match := range matches {
		username := match[1]
		var mentionedUser models.User
		if err := config.DB.Where("username = ?", username).First(&mentionedUser).Error; err == nil {
			if mentionedUser.ID != senderID {
				title := "New Mention"
				body := sender.Username + " mentioned you in " + sourceTitle
				CreateNotification(mentionedUser.ID, "mention", title, body)
				if mentionedUser.FCMToken != "" {
					SendFCMNotification(mentionedUser.FCMToken, title, body)
				}
			}
		}
	}
}
