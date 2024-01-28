#!/usr/bin/env bash

# ubuntu的 安装脚本
function installDockerUbuntu() {
    # Add Docker's official GPG key:
    sudo apt update
    sudo apt install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# 使用官方脚本安装
function installDockerSh() {
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    systemctl enable docker
    systemctl start docker
}

# 安装docker
function installDocker() {
    installDockerSh
}