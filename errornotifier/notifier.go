package errornotifier

import (
	"net/http"

	"github.com/dwilkie/gobrake"
)

type Notifier interface {
	Notify(err error, request *http.Request) error
}

type ErrbitNotifier struct {
	errbitClient *gobrake.Notifier
}

func NewErrbitNotifier(host, apiKey, envName string) ErrbitNotifier {
	errbitClient := gobrake.NewNotifier(0, apiKey, host)
	errbitClient.SetContext("environment", envName)

	return ErrbitNotifier{
		errbitClient: errbitClient,
	}
}

func (en ErrbitNotifier) Notify(err error, request *http.Request) error {
	return en.errbitClient.Notify(err, request)
}
