# Building

## Ensure multiplatform building is supported

* Install `docker-buildx`
* Check if all the platforms are available

```
$ docker buildx ls
NAME/NODE         DRIVER/ENDPOINT             STATUS  BUILDKIT             PLATFORMS
default           docker
  default         default                     running v0.11.6+0a15675913b7 linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386, linux/arm64, linux/riscv64, linux/ppc64, linux/ppc64le, linux/s390x, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
```

You may only see `amd64` platforms. If so, use this to fix it:

`docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`

After this, it may still be necessary to create a new builder, even though the default one shows the correct platforms.

`docker buildx create --use`

## Build and publish

`docker buildx build --platform linux/amd64,linux/arm64 -t technosam/qbittorrent-gluetun-port-update:$version -t technosam/qbittorrent-gluetun-port-update:latest --push .`

If you rebuild without making changes to the script or Dockerfile, the digest should be the same. This is useful if you forget to include the correct tags.

## Development building

From the repository root, run `./build/dev-build.sh`. This script force-removes any existing image and builds a new one.
