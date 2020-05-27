#!/bin/bash -e
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation

DIR=$(dirname $(readlink -f "$0"))

echo "Making volumes..."
HOSTS=$(kubectl get node -o 'custom-columns=NAME:.status.addresses[?(@.type=="Hostname")].address,IP:.status.addresses[?(@.type=="InternalIP")].address' | awk '!/NAME/{print $1":"$2}')
echo $HOSTS
awk -v DIR="${DIR}/CDN-Transcode-Sample/deployment/kubernetes" -v HOSTS="$HOSTS" '
BEGIN{
    split(HOSTS,tmp1," ");
    for (i in tmp1) {
        split(tmp1[i],tmp2,":");
        host2ip[tmp2[1]]=tmp2[2];
    }
}
/name:/ {
    gsub("-","/",$2)
    content="\""DIR"/../../volume/"$2"\""
}
/path:/ {
    path=$2
}
/- ".*"/ {
    host=host2ip[substr($2,2,length($2)-2)];
    system("ssh "host" \"mkdir -p "path";find "path" -mindepth 1 -maxdepth 1 -exec rm -rf {} \\\\;\"");
    if (path == "/tmp/archive/video") {
        system("scp -r "content"/* "host":"path);
    }
}
END {
    system("echo finished...")
}
' "$DIR/CDN-Transcode-Sample/deployment/kubernetes"/*-pv.yaml
