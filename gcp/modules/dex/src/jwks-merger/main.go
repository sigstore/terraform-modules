package jwksmerger

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"cloud.google.com/go/storage"
	"github.com/cloudevents/sdk-go/v2/event"
	"google.golang.org/api/iterator"
)

type StorageObjectData struct {
	Bucket string `json:"bucket"`
	Name   string `json:"name"`
}

type JWKS struct {
	Keys []json.RawMessage `json:"keys"`
}

func MergeKeys(ctx context.Context, e event.Event) error {
	var data StorageObjectData
	if err := e.DataAs(&data); err != nil {
		return fmt.Errorf("failed to parse event: %v", err)
	}

	// 1. Prevent infinite loops
	if !strings.HasPrefix(data.Name, "keys/") {
		log.Printf("Ignoring file outside keys/ directory: %s", data.Name)
		return nil
	}

	client, err := storage.NewClient(ctx)
	if err != nil {
		return fmt.Errorf("failed to create storage client: %v", err)
	}
	defer client.Close()

	bucket := client.Bucket(data.Bucket)
	var mergedKeys []json.RawMessage

	// 2. Dynamically list all files in the "keys/" directory
	query := &storage.Query{Prefix: "keys/"}
	it := bucket.Objects(ctx, query)

	for {
		attrs, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return fmt.Errorf("error listing bucket objects: %v", err)
		}

		// Skip the directory itself if GCS reports it as a 0-byte object
		if attrs.Name == "keys/" {
			continue
		}

		// 3. Read and merge each discovered file
		reader, err := bucket.Object(attrs.Name).NewReader(ctx)
		if err != nil {
			log.Printf("Warning: Could not read %s: %v", attrs.Name, err)
			continue
		}

		var jwks JWKS
		if err := json.NewDecoder(reader).Decode(&jwks); err != nil {
			log.Printf("Error decoding JSON from %s: %v", attrs.Name, err)
			reader.Close()
			continue
		}
		reader.Close()

		mergedKeys = append(mergedKeys, jwks.Keys...)
		log.Printf("Successfully merged keys from %s", attrs.Name)
	}

	// 4. Write the final result
	finalJWKS := JWKS{Keys: mergedKeys}
	finalJSON, err := json.Marshal(finalJWKS)
	if err != nil {
		return fmt.Errorf("failed to marshal merged keys: %v", err)
	}

	writer := bucket.Object("public/keys.json").NewWriter(ctx)
	writer.ContentType = "application/json"
	writer.CacheControl = "public, max-age=60"

	if _, err := writer.Write(finalJSON); err != nil {
		return fmt.Errorf("failed to write final json: %v", err)
	}
	if err := writer.Close(); err != nil {
		return fmt.Errorf("failed to close writer: %v", err)
	}

	log.Printf("Successfully published merged JWKS with %d total keys.", len(mergedKeys))
	return nil
}
