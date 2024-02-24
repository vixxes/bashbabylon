#!/bin/bash

function line {
  echo -e "${GREEN}-----------------------------------------------------------------------------${NORMAL}"
}

function install_go {
    sudo rm -rvf /usr/local/go/
    wget https://golang.org/dl/go1.21.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz
    rm go1.21.1.linux-amd64.tar.gz
    sleep 1
}

function configure_go {
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export GO111MODULE=on
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    sleep 1
}

function buildessential {
    sudo apt install git build-essential curl jq --yes
    sleep 1
}

function source_build_git {
    cd $HOME
    git clone https://github.com/babylonchain/babylon.git
    cd babylon
    git checkout v0.8.3

    make build

    make install
}

function initnode {
    babylond init $MONIKER --chain-id bbn-test-3

    wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
    tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
    mv genesis.json ~/.babylond/config/genesis.json

    sed -i -e "s|^seeds *=.*|seeds = \"49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656\"|" $HOME/.babylond/config/config.toml

    peers="5463943178cdb57a02d6d20964e4061dfcf0afb4@142.132.154.53:20656,3774fb9996de16c2f2280cb2d938db7af88d50be@162.62.52.147:26656,9d840ebd61005b1b1b1794c0cf11ef253faf9a84@43.157.95.203:26656,0ccb869ba63cf7730017c357189d01b20e4eb277@185.84.224.125:20656,3f5fcc3c8638f0af476e37658e76984d6025038b@134.209.203.147:26656,163ba24f7ef8f1a4393d7a12f11f62da4370f494@89.117.57.201:10656,1bdc05708ad36cd25b3696e67ac455b00d480656@37.60.243.219:26656,59df4b3832446cd0f9c369da01f2aa5fe9647248@65.109.97.139:26656,e3b214c693b386d118ea4fd9d56ea0600739d910@65.108.195.152:26656,c0ee3e7f140b2de189ce853cfccb9fb2d922eb66@95.217.203.226:26656,e46f38454d4fb889f5bae202350930410a23b986@65.21.205.113:26656,35abd10cba77f9d2b9b575dfa0c7c8c329bf4da3@104.196.182.128:26656,6f3f691d39876095009c223bf881ccad7bd77c13@176.227.202.20:56756,1ecc4a9d703ad52d16bf30a592597c948c115176@165.154.244.14:26656,0c9f976c92bcffeab19944b83b056d06ea44e124@5.78.110.19:26656,c3e82156a0e2f3d5373d5c35f7879678f29eaaad@144.76.28.163:46656,b82b321380d1d949d1eed6da03696b1b2ef987ba@148.251.176.236:3000,eee116a6a816ca0eb2d0a635f0a1b3dd4f895638@84.46.251.131:26656,894d56d58448a158ed150b384e2e57dd7895c253@164.92.216.48:26656,ddd6f401792e0e35f5a04789d4db7dc386efc499@135.181.182.162:26656,326fee158e9e24a208e53f6703c076e1465e739d@193.34.212.39:26659,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,fad3a0485745a49a6f95a9d61cda0615dcc6beff@89.58.62.213:26501,ce1caddb401d530cc2039b219de07994fc333dcf@162.19.97.200:26656,66045f11c610b6041458aa8553ffd5d0241fd11e@103.50.32.134:56756,82191d0763999d30e3ddf96cc366b78694d8cee1@162.19.169.211:26656"
    sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" $HOME/.babylond/config/config.toml

    sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ubbn\"|" $HOME/.babylond/config/app.toml

    sed -i -e "s|^network *=.*|network = \"signet\"|" $HOME/.babylond/config/app.toml
}

function systemd {
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

    mkdir -p ~/.babylond
    mkdir -p ~/.babylond/cosmovisor
    mkdir -p ~/.babylond/cosmovisor/genesis
    mkdir -p ~/.babylond/cosmovisor/genesis/bin
    mkdir -p ~/.babylond/cosmovisor/upgrades

    mv build/babylond $HOME/.babylond/cosmovisor/genesis/bin/
    rm -rf build

    
    sudo tee /etc/systemd/system/babylon.service > /dev/null << EOF
Unit]
Description=Babylon daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=babylond"
Environment="DAEMON_HOME=${HOME}/.babylond"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable babylon.service
sudo -S systemctl start babylond
}

function start {
    sudo systemctl status babylon
}

function main {
    line
    install_go
    line
    configure_go
    line
    buildessential
    line
    source_build_git
    line
    initnode
    line
    systemd
    line
    start
}

main