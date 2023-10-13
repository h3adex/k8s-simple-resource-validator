package main

import (
	"encoding/json"
	v1 "k8s.io/api/admission/v1"
	v12 "k8s.io/api/core/v1"
	v13 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"net/http"
)

func validateResources(w http.ResponseWriter, r *http.Request) {
	admissionReview := v1.AdmissionReview{}
	err := json.NewDecoder(r.Body).Decode(&admissionReview)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
	}

	admissionResponse := &v1.AdmissionResponse{
		Allowed: true,
		UID:     admissionReview.Request.UID,
	}

	p := v12.Pod{}
	if err := json.Unmarshal(admissionReview.Request.Object.Raw, &p); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
	}

	for _, container := range p.Spec.Containers {
		if container.Resources.Requests.Cpu().IsZero() {
			admissionResponse.Allowed = false
			admissionResponse.Result = &v13.Status{
				Code:    http.StatusBadRequest,
				Message: "CPU request not set",
			}
		}

		if container.Resources.Requests.Memory().IsZero() {
			admissionResponse.Allowed = false
			admissionResponse.Result = &v13.Status{
				Code:    http.StatusBadRequest,
				Message: "Memory request not set",
			}
		}

		if container.Resources.Limits.Memory().IsZero() {
			admissionResponse.Allowed = false
			admissionResponse.Result = &v13.Status{
				Code:    http.StatusBadRequest,
				Message: "Memory limit not set",
			}
		}

		if !container.Resources.Limits.Cpu().IsZero() {
			admissionResponse.Allowed = false
			admissionResponse.Result = &v13.Status{
				Code:    http.StatusBadRequest,
				Message: "CPU limit should not be set",
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	err = json.NewEncoder(w).Encode(v1.AdmissionReview{
		TypeMeta: admissionReview.TypeMeta,
		Response: admissionResponse,
	})

	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
	}

}

func main() {
	http.HandleFunc("/validate", validateResources)
	err := http.ListenAndServeTLS(":8080", "/etc/ssl/certs/tls.crt", "/etc/ssl/certs/tls.key", nil)
	if err != nil {
		return
	}
}
