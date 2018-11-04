package main

import (
	"context"
	"github.com/gin-gonic/gin"
	"github.com/thiago-dev/nginx-rtmp-go/api/api"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
)

var listenAddr string

func init() {
	listenAddr = os.Getenv("LISTEN_ADDR")
	if listenAddr == "" {
		listenAddr = ":3000"
	}
	// Disable console color
	gin.DisableConsoleColor()
	// enable release mode
	gin.SetMode(gin.ReleaseMode)
}

func main() {
	router := gin.Default()
	router.POST("/on_publish", api.OnPublish)

	// inform user if no api key were set
	if os.Getenv("STREAM_KEY") == "" {
		log.Println("no stream key set. check will always return 200.")
	}

	srv := &http.Server{
		Addr: listenAddr,
		// Good practice to set timeouts to avoid Slowloris attacks.
		WriteTimeout: time.Second * 15,
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler: router,
	}

	// Run our server in a goroutine so that it doesn't block.
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()
	// Wait for interrupt signal to gracefully shutdown the server with
	// a timeout of 5 seconds.
	quit := make(chan os.Signal)
	signal.Notify(quit, os.Interrupt)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server Shutdown:", err)
	}
	log.Println("Exiting..")
}

