resource "local_file" "httproute_django" {
  content = <<EOF
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: webapp
spec:
  parentRefs:
  - kind: Gateway
    name: external-http-gateway
  hostnames:
  - "${module.addresses-gcp.global_addresses["gateway-ext-lb"].address}.nip.io"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: django-service
      port: 8000
EOF

  filename = "../../weather-scanner-django/manifests/http-route.yaml"
}
