#!/bin/sh

# Spin up a container.
id=`docker run --rm --detach -it crux-bitcode:latest bash`
# Short ID, for more wieldy filenames.
sid=`echo $id | head -c 10`

# Copy over user config.
docker cp pkgmk.conf $id:/etc/pkgmk.conf
docker cp pkgs.txt $id:/etc/pkgs.txt

docker exec "$id" build-bitcode
docker exec "$id" mv "bitcode" "bitcode-$sid"
docker exec "$id" zip -r "bitcode-$sid.zip" "bitcode-$sid"

docker cp "$id:/root/bitcode-$sid.zip" "bitcode-$sid.zip"

docker stop "$id"
