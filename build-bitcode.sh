#!/bin/sh

usage() {
  echo "usage: $0 [-s]"
  echo "  -s  extract source code"
}

sources=0
while getopts ':sh' opt; do
  case $opt in
    s)
      sources=1
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

# Spin up a container.
id=`docker run --rm --detach -it mbarbar/crux-bitcode:12.0.0.0 bash`
# Short ID, for more wieldy filenames.
sid=`echo $id | head -c 10`

# Copy over user config.
docker cp pkgmk.conf $id:/etc/pkgmk.conf
docker cp pkgs.txt $id:/etc/pkgs.txt
docker cp ports/. $id:/usr/ports/

if docker exec "$id" build-bitcode; then
  docker exec "$id" mv "bitcode" "bitcode-$sid"
  docker exec "$id" zip -r "bitcode-$sid.zip" "bitcode-$sid"
  docker cp "$id:/root/bitcode-$sid.zip" "bitcode-$sid.zip"

  echo "BITCODE: bitcode-$sid.zip"

  # TODO: actually prevent copying from going on in the image.
  if [ $sources = 1 ]; then
    docker exec "$id" mv "source" "source-$sid"
    docker exec "$id" zip -r "source-$sid.zip" "source-$sid"
    docker cp "$id:/root/source-$sid.zip" "source-$sid.zip"

    echo "SOURCE: source-$sid.zip"
  fi
else
  echo "^ fatal error" 1>&2
fi

docker stop "$id" > /dev/null
