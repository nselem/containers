#!/bin/bash
build_vars() {
    build_image_base=radiasoft/beamsim
    boot_dir=$build_run_user_home/.radia-run
    tini_file=$boot_dir/tini
    radia_run_boot=$boot_dir/start
    build_docker_cmd='["'"$tini_file"'", "--", "'"$radia_run_boot"'"]'
    build_dockerfile_aux="USER $build_run_user"
}

build_as_run_user() {
    cd "$build_guest_conf"
    build_vars
    local notebook_dir_base=jupyter
    export notebook_dir=$build_run_user_home/$notebook_dir_base
    export jupyterhub_singleuser=$boot_dir/jupyterhub-singleuser
    export boot_dir
    export notebook_bashrc="$notebook_dir_base/bashrc"
    export notebook_template_dir="$boot_dir/$notebook_dir_base"
    # Make sure these are up to date, fixes we need only in dev version
    pip install -U 'git+git://github.com/jupyter/notebook.git@4e359c921fb503ba3782a67cbd5ed221b081a478'
    # POSIT: notebook_dir in salt-conf/srv/pillar/jupyterhub/base.yml
    mkdir -p ~/.jupyter "$notebook_dir" "$notebook_template_dir"
    replace_vars jupyter_notebook_config.py ~/.jupyter/jupyter_notebook_config.py
    replace_vars radia-run.sh "$radia_run_boot"
    chmod +x "$radia_run_boot"
    build_curl https://github.com/krallin/tini/releases/download/v0.9.0/tini > "$tini_file"
    chmod +x "$tini_file"
    # Needed to run jupyterhub-singleuser script
    # pip install -U git+git://github.com/jupyterhub/jupyterhub.git
    # build_curl https://raw.githubusercontent.com/jupyter/jupyterhub/master/scripts/jupyterhub-singleuser | perl -p -e 's/python3/python/' > "$jupyterhub_singleuser"
    build_curl https://raw.githubusercontent.com/jupyterhub/jupyterhub/d9d68efa55afb57d40c23257a2915aa1337aef92/scripts/jupyterhub-singleuser > "$jupyterhub_singleuser"
    chmod +x "$jupyterhub_singleuser"
    replace_vars post_bivio_bashrc ~/.post_bivio_bashrc
    local f
    for f in bashrc requirements.txt; do
        replace_vars "$f" "$notebook_template_dir/$f"
    done
}

replace_vars() {
    local src=$1
    local dst=$2
    perl -p -e 's/\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' "$src" > "$dst"
}

build_vars
