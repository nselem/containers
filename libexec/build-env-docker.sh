#!/bin/bash
#
# Docker functions and variables for build
#
build_env_docker_image_exists() {
    local img=$1
    docker images -a | grep -s -q "^${img/:/ *} "
}

if ! build_env_docker_image_exists "$build_base_docker"; then
    build_err "$build_base_docker: not in docker images -a"
fi

# Docker's hardwired container network
build_container_net=172.17.42

build_clean_dir() {
    true
}

build_clean_box() {
    if ! build_env_docker_image_exists "$build_box"; then
        return
    fi
    #TODO(robnagler) is this safe?
    # Remove none running containers.
    for f in $(docker ps -a \
            | perl -n -e "m{^(\w+)\s.*\s\Q$build_box\E[\s:]} && print(qq{\$1\n})"); do
        docker rm "$f"
    done
    docker rmi "$build_box"
}

build_run() {
    rm -f Dockerfile
    cat > Dockerfile <<EOF
FROM $build_base_docker
MAINTAINER RadiaSoft <docker@radiasoft.net>
ADD . $build_conf
ENV "build_env=$build_env"
RUN bash "$build_script"
EOF
    local version=$(date -u +%Y%m%d.%H%M%S)
    docker build --rm=true --tag="$build_box:$version" .
    docker tag -f "$build_box:$version" "$build_box:latest"
    echo "Built: $build_box:$version"
}
