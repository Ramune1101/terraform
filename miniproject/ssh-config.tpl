cat << EOF > ~/.ssh.config

Host ${hostname}
  HostName ${hostname}
  IdentityFile ${identityfile}
  User ${username}
  ForwardAgent yes
EOF

chmod 600 ~/.ssh/config
