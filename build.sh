#!/bin/bash

NGINX_VERSIONS=(1.19)

###############################

green () {
    echo -e "\033[1;32m$1\033[0m"
}
die () {
    echo; echo -e "\033[1;31mERROR:\033[0m $1"; echo; exit 1
}

for v in ${NGINX_VERSIONS[@]}; do

    IMAGE="pure/nginx:${v}-alpine-ext"

    green "Build custom Nginx image for ${v}"
    docker build --pull --build-arg VER=${v} -f Dockerfile -t ${IMAGE} . || die "Can't build docker image"
    echo
done

for v in ${NGINX_VERSIONS[@]}; do

    IMAGE="pure/nginx:${v}-alpine-ext"

    green "Push image for ${v}"
    docker push ${IMAGE} || die "Can't push docker image"
    echo
done

cat README.tmpl >README.md
for v in ${NGINX_VERSIONS[@]}; do
    IMAGE="pure/nginx:${v}-alpine-ext"
    echo "- **${v}** - \`${IMAGE}\`" >>README.md
done
echo >>README.md

echo; green "Done!"; echo
