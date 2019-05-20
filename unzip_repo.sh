#!/bin/bash

set -eu
set -o pipefail

function unziprepo () {
    repo=$1
    filename=${!repo}
    mkdir -p /work/${repo}
    cd /work/${repo}
    cp /vagrant/${filename} .
    unzip -q ${filename}
}

IIM=agent.installer.linux.gtk.x86_64_1.8.9004.20190423_2015.zip
WAS=WAS_ND_V9.0_MP_ML.zip
JDK=sdk.repo.8030.java8.linux.zip
IHS=was.repo.9000.ihs.zip
PLG=was.repo.9000.plugins.zip
WAS_FP=9.0.0-WS-WAS-FP011.zip
JDK_FP=ibm-java-sdk-8.0-5.35-linux-x64-installmgr.zip
IHSPLG_FP=9.0.0-WS-IHSPLG-FP011.zip

unziprepo IIM
unziprepo WAS
unziprepo JDK
unziprepo IHS
unziprepo PLG
unziprepo WAS_FP
unziprepo JDK_FP
unziprepo IHSPLG_FP
