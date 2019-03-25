#!/bin/sh

noflags() {
        echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    echo "Usage: foxcoin"
    echo "Example: foxcoin"
    echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    exit 1
}

message() {
        echo "╒═════════════════════════════════════<<<**>>>═══════════════════════════════════>>>"
        echo "|"
        echo "| $1"
        echo "|"
        echo "╘═════════════════════════════════════<<<**>>>═══════════════════════════════════>>>"
}

error() {
        message "An error occured, you must fix it to continue!"
        exit 1
}

prepdependencies() { #TODO: add error detection
        message "Installing dependencies..."
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
        sudo apt-get install automake libdb++-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev libboost-all-dev libminiupnpc-dev git software-properties-common g++ bsdmainutils libevent-dev -y
        sudo add-apt-repository ppa:bitcoin/bitcoin -y
        sudo apt-get update
        sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
}

createswap() { #TODO: add error detection
        message "Creating 2GB temporary swap file...this may take a few minutes..."
        sudo dd if=/dev/zero of=/swapfile bs=1M count=2000
        sudo mkswap /swapfile
        sudo chown root:root /swapfile
        sudo chmod 0600 /swapfile
        sudo swapon /swapfile

        #make swap permanent
        sudo echo "/swapfile none swap sw 0 0" >> /etc/fstab
}
clonerepo() { #TODO: add error detection
        message "Cloning from github repository..."
        cd ~/
        git clone https://github.com/foxcoinreborn/foxcoin.git
	chmod a+x+w -R foxcoin/
}
compile() {
        cd foxcoin #TODO: squash relative path
        message "Preparing to build..."
        ./autogen.sh
        if [ $? -ne 0 ]; then error; fi
        message "Configuring build options..."
        ./configure $1 --disable-tests --with-gui=no
        if [ $? -ne 0 ]; then error; fi
        message "Building foxcoin...this may take a few minutes..."
        chmod 777 share/genbuild.sh && make
        if [ $? -ne 0 ]; then error; fi
        message "Installing foxcoin..."
        sudo make install
        if [ $? -ne 0 ]; then error; fi
}

createconf() {
        #TODO: Can check for flag and skip this
        #TODO: Random generate the user and password

        message "Creating adevplus20.conf..."
        MNPRIVKEY="66M7PXr6q8LCQdafoAwoxa927T2jowafosA7vAYAPnRMw3BYX4a"
        CONFDIR=~/.foxcoin
        CONFILE=$CONFDIR/foxcoin.conf
        if [ ! -d "$CONFDIR" ]; then mkdir $CONFDIR; fi
        if [ $? -ne 0 ]; then error; fi

        mnip=$(curl -s https://api.ipify.org)
        rpcuser=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
        rpcpass=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
        printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" > $CONFILE

        foxcoind
        message "Wait 10 seconds for daemon to load..."
        sleep 10s
        MNPRIVKEY=$(adevplus20-cli masternode genkey)
        foxcoin-cli stop
        message "wait 10 seconds for deamon to stop..."
        sleep 10s
        sudo rm $CONFILE
        message "Updating adevplus20.conf..."
        printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcport=5471" "rpcallowip=127.0.0.1" "externalip=$mnip:25676" "listen=1" "server=1" "daemon=1" "maxconnections=256" "masternode=1" "masternodeprivkey=$MNPRIVKEY" > $CONFILE

}
success() {
        foxcoind
        message "SUCCESS! Your Foxcoin has started. Masternode.conf setting below..."
        message "MN $mnip:5472 $MNPRIVKEY TXHASH INDEX"
        exit 0
}

install() {
        prepdependencies
        createswap
        clonerepo
        compile $1
        createconf
        success
}

#main
#default to --without-gui
install --without-gui


##### Main #####
clear

purgeOldInstallation
checks
prepare_system
download_node
setup_node
