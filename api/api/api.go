package api

import (
	"errors"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
)

// Error which will be returned on any error regarding the key
var ErrNoOrWrongKeyProvided = errors.New("publishing failed due to no or wrong streamKey provided")

// PublishRequest maps the post request coming from nginx
// because we are only interested in the provided streamKey the other
// possible fields were omitted.
// from: https://github.com/arut/nginx-rtmp-module/wiki/Directives#on_publish
// HTTP request receives a number of arguments. POST method is used with application/x-www-form-urlencoded MIME type.
// The following arguments are passed to caller:
//
//	call=play
//	addr - client IP address
//	clientid - nginx client id (displayed in log and stat)
//	app - application name
//	flashVer - client flash version
//	swfUrl - client swf url
//	tcurl - tcUrl
//	pageUrl - client page url
//	name - stream name
type PublishRequest struct {
	TcURL string `form:"tcurl"`
}

// OnPublish will receive PublishRequest a like request from nginx on every publish attempt.
// Here we validate the provided key and return 200 if key is correct otherwise 401.
func OnPublish(c *gin.Context) {
	apiKey := os.Getenv("STREAM_KEY")
	// if no key were set in env variable, disable checking and just return 200
	if apiKey == "" {
		c.Status(200)
		return
	}
	req := &PublishRequest{}
	err := c.Bind(req)

	if err != nil {
		c.AbortWithError(http.StatusBadRequest, err)
		return
	}
	key, err := getKeyFromRequest(req)
	if err != nil {
		c.AbortWithError(http.StatusUnauthorized, err)
		return
	}

	// is the key OK?
	if key == apiKey {
		c.Status(200)
		return
	}

	// key was not ok; disallow publishing
	c.AbortWithError(http.StatusUnauthorized, ErrNoOrWrongKeyProvided)
}

// getKeyFromRequest is a simple helper function which returns the key or an error
// from request
func getKeyFromRequest(req *PublishRequest) (string, error) {
	v, err := url.ParseQuery(strings.Split(req.TcURL, "?")[1])
	if err != nil {
		return "",err
	}
	log.Println(v.Encode())
	key := v.Get("key")
	if key == "" {
		return "", ErrNoOrWrongKeyProvided
	}
	return key, nil
}
