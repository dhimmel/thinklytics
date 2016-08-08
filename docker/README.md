# Docker to create the thinklytics environment

Build the docker image with the following commands:

```sh
TAG="dhimmel/thinklytics:v0.1"
docker build --tag dhimmel/thinklytics:latest --tag $TAG --file Dockerfile .
```

See the image on Docker hub at [`dhimmel/thinklytics`](https://hub.docker.com/r/dhimmel/thinklytics/).

Run the Docker and perform the analysis by running the following from the repository's root directory:

```sh
docker run \
  --volume `pwd`:/thinklytics \
  --workdir /thinklytics \
  dhimmel/thinklytics \
  sh run.sh
```
