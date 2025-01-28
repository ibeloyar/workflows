//go:build tools
// +build tools

package tools

// tools need for generation
import (
	// // Code generation
	// _ "github.com/alvaroloes/enumer"

	// // Base tools
	// _ "mvdan.cc/gofumpt"

	// gRPC tools
	// _ "github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2"
	_ "google.golang.org/grpc/cmd/protoc-gen-go-grpc"
	_ "google.golang.org/protobuf/cmd/protoc-gen-go"
)
