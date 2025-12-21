package services

import (
	"encoding/json"
	"strings"
)

// ParseOptions converts a string (JSON array or comma-separated) into a slice of strings
func ParseOptions(raw string) []string {
	var options []string

	// Try parsing as JSON first
	err := json.Unmarshal([]byte(raw), &options)
	if err == nil {
		return options
	}

	// Fallback to comma separation
	parts := strings.Split(raw, ",")
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			options = append(options, trimmed)
		}
	}

	return options
}
