#!/bin/bash
set -e

USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}

# Create group and user with matching IDs
if ! getent group madgraph > /dev/null 2>&1; then
    groupadd -g "$GROUP_ID" madgraph
fi

if ! getent passwd madgraph > /dev/null 2>&1; then
    useradd -u "$USER_ID" -g "$GROUP_ID" -m -s /bin/bash madgraph
fi

# Allow madgraph user to use sudo without password
echo "madgraph ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/madgraph
chmod 0440 /etc/sudoers.d/madgraph

# Ensure the working directory is accessible
chown "$USER_ID":"$GROUP_ID" /madgraph

# Persist shell history in the mounted workspace across run --rm sessions.
touch /madgraph/.bash_history
chown "$USER_ID":"$GROUP_ID" /madgraph/.bash_history
chmod 600 /madgraph/.bash_history

if ! grep -q "hep-pipeline-env history" /home/madgraph/.bashrc 2>/dev/null; then
    cat <<'EOF' >> /home/madgraph/.bashrc
# hep-pipeline-env history
export HISTFILE=/madgraph/.bash_history
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend
history -r "$HISTFILE" 2>/dev/null || true
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
EOF
fi

chown "$USER_ID":"$GROUP_ID" /home/madgraph/.bashrc

if [ ! -f /madgraph/.bootstrap_done ]; then
    gosu madgraph bash -lc 'cd /madgraph && source /madgraph/compile_all.sh'
fi

exec gosu madgraph bash -lc 'cd /madgraph && source /madgraph/compile_all.sh >/dev/null 2>&1 || true; exec "$@"' _ "$@"
