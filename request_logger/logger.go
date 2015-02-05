package request_logger

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/codegangsta/negroni"
)

type logEntry struct {
	Timestamp time.Time              `json:"@timestamp"`
	Fields    map[string]interface{} `json:"@fields"`
	Tags      []string               `json:"@tags"`
}

type logger struct {
	writer io.Writer
	lines  chan *[]byte
}

// New creates a new request logging middleware.   The output variable sets the
// destination to which log data will be written.  This can be either an
// io.Writer, or a string.  With the latter, this is either one of "STDOUT" or
// "STDERR", or the path to the file to log to.
func New(output interface{}) (negroni.Handler, error) {
	var err error
	l := &logger{}
	l.writer, err = openWriter(output)
	if err != nil {
		return nil, err
	}
	l.lines = make(chan *[]byte, 100)
	go l.writeLoop()
	return l, nil
}

func openWriter(output interface{}) (io.Writer, error) {
	switch out := output.(type) {
	case io.Writer:
		return out, nil
	case string:
		if out == "STDERR" {
			return os.Stderr, nil
		} else if out == "STDOUT" {
			return os.Stdout, nil
		} else {
			w, err := os.OpenFile(out, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0600)
			if err != nil {
				return nil, err
			}
			return w, nil
		}
	default:
		return nil, fmt.Errorf("Invalid output type %T(%v)", output, output)
	}
}

func (l *logger) writeLoop() {
	for {
		line := <-l.lines
		_, err := l.writer.Write(*line)
		if err != nil {
			log.Printf("Error writing to log: %v", err)
		}
	}
}

func (l *logger) ServeHTTP(rw http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	start := time.Now()

	next(rw, r)

	duration := time.Since(start)
	res := rw.(negroni.ResponseWriter)

	entry := &logEntry{
		Timestamp: time.Now(),
		Fields: map[string]interface{}{
			"method":       r.Method,
			"path":         r.URL.Path,
			"query_string": r.URL.RawQuery,
			"request":      fmt.Sprintf("%s %s %s", r.Method, r.RequestURI, r.Proto),
			"remote_addr":  r.RemoteAddr,
			"status":       res.Status(),
			"duration":     float64(duration.Nanoseconds()/1000) / 1000, // Milliseconds to 3dp
			"length":       res.Size(),
		},
		Tags: []string{"request"},
	}

	line, err := json.Marshal(entry)
	if err != nil {
		log.Printf("request_logger: Error encoding JSON: %v", err)
	}

	line = append(line, 10) // Append a newline
	l.lines <- &line
}
