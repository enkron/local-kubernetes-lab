# create dockerhub creds

```bash
kubectl create secret docker-registry dockerhub-creds \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=<USERNAME> \
    --docker-password=<PASSWORD>
```

# create a namespace

```bash
kubectl create namespace ci # creates the namespace called 'ci'
```

# create admin service account manifest, volume, deployment manifest & service

change `nodeAffinity` selector to the hostname of a worker node in the `volume.yml`

```bash
kubectl apply -f '*.yml'
```
