# Install Go
echo "Goooooolang setup"
go=$(curl https://go.dev/dl/ -s 2>/dev/null | grep linux | grep amd64 | head -n 1 | awk -F \" '{print $4}')
wget https://go.dev$go
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $(echo $go | awk -F "/" '{print $3}')
rm -rf $(echo $go | awk -F "/" '{print $3}')
mkdir -p ~/go
echo -e "export PATH=~/.local/bin:$PATH\nexport PATH=$PATH:/usr/local/go/bin\nexport GOPATH=$HOME/go\nexport PATH=$PATH:$GOPATH/bin\n" >> ~/.zshrc


git clone https://github.com/HavocFramework/Havoc.git
cd Havoc
sudo apt install -y git build-essential apt-utils cmake libfontconfig1 libglu1-mesa-dev libgtest-dev libspdlog-dev libboost-all-dev libncurses5-dev libgdbm-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev mesa-common-dev qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5websockets5 libqt5websockets5-dev qtdeclarative5-dev golang-go qtbase5-dev libqt5websockets5-dev python3-dev libboost-all-dev mingw-w64 nasm
sudo apt install -y curl zsh tmux vim binutils gobuster seclists dirsearch libncurses5:i386 libstdc++6:i386 openjdk-17-jdk
sudo apt install -y arandr flameshot arc-theme feh i3blocks i3status i3 i3-wm lxappearance python3-pip rofi unclutter cargo compton papirus-icon-theme imagemagick
sudo apt install -y libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev autoconf meson apt-transport-https neo4j bloodhound
sudo apt install -y libxcb-render-util0-dev libxcb-shape0-dev libxcb-xfixes0-dev 

# Check to see if this go stuff will work out of the box on a fresh kali, might need to have a go install.
cd teamserver
go mod download golang.org/x/sys
go mod download github.com/ugorji/go
cd ..

# Build the client Binary (From Havoc Root Directory)
make ts-build
make client-build

# Run the teamserver
echo "./havoc server --profile ../profiles/office365.yaotl -v --debug"