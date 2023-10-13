# K8s-Simple-Resource-Validator

Based on the insights shared in the [article](https://home.robusta.dev/blog/stop-using-cpu-limits)
by Nathan Yellin at robusta.dev, I've created a simple resource validator for k8s deployments, 
which verifies if your resource limits and requests are appropriately configured

Please note that this repository was primarily crafted to explore the Kubernetes Admission Webhook feature.
For production environments, there are probably better choices.

## Development
```shell
# gen self signed certs
make certs
# create a kind k8s cluster and deploy the manifests in dev directory
make build 
```
