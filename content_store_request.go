package main

type ContentStoreRequest struct {
	BasePath      string `json:"base_path"`
	PublishingApp string `json:"publishing_app"`
	UpdateType    string `json:"update_type"`
}
