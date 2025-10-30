#!/usr/bin/env bash
set -e

sudo apt-get -yqq update
sudo apt-get -yqq remove tmux || true
sudo apt-get -yqq install libevent-dev ncurses-dev build-essential bison pkg-config automake git ruby zsh

git clone https://github.com/tmux/tmux.git /tmp/latest_tmux
cd /tmp/latest_tmux
sh autogen.sh && ./configure && make
sudo make install
cd ~

mkdir -p ~/.tmux/plugins ~/.config/tmuxinator ~/logs/tmux

cat > ~/.tmux.conf <<'EOF'
set-option -g default-shell /bin/zsh
set -g @plugin 'tmux-plugins/tmux-logging'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g history-limit 250000
set -g allow-rename off
set -g escape-time 50
set-window-option -g mode-keys vi
run '~/.tmux/plugins/tpm/tpm'
run '~/.tmux/plugins/tmux-logging/logging.tmux'
run '~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh'
bind-key "c" new-window \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"
bind-key '"' split-window \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"
bind-key "%" split-window -h \; run-shell "~/.tmux/plugins/tmux-logging/scripts/toggle_logging.sh"
EOF

rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh || true
sed -i 's|default_logging_path="$HOME"|default_logging_path="~/logs/tmux"|' ~/.tmux/plugins/tmux-logging/scripts/variables.sh || true
tmux new-session -d || true
tmux source-file ~/.tmux.conf || true
gem install --user-install tmuxinator --no-document

cat > ~/.config/tmuxinator/default.yml <<'EOF'
name: default
root: ~/
windows:
  - main: tmux source ~/.tmux.conf
  - msf: msfconsole
EOF

echo "✅ Setup complete. Run 'tmux' or 'tmuxinator start default'"
