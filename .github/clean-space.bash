#!/usr/bin/env bash
# Clean up as much runner disk space as possible
# Taken from https://github.com/lilyinstarlight/foosteros/blob/aa611d0cf03bd82f6c1c701e73f86f27abb8d8e4/.github/workflows/installer.yml
# which is MIT licensed

# Large docker images
sudo docker image prune --all --force

# Large packages
sudo apt-get purge -y '^llvm-.*' 'php.*' '^mongodb-.*' '^mysql-.*' azure-cli google-cloud-cli google-chrome-stable firefox powershell microsoft-edge-stable
sudo apt-get autoremove -y
sudo apt-get clean

# Large folders
sudo rm -rf /var/lib/apt/lists/* /opt/hostedtoolcache /usr/local/games /usr/local/sqlpackage /usr/local/.ghcup /usr/local/share/powershell /usr/local/share/edge_driver
sudo rm -rf /usr/local/share/gecko_driver /usr/local/share/chromium /usr/local/share/chromedriver-linux64 /usr/local/share/vcpkg /usr/local/lib/python*
sudo rm -rf /usr/local/lib/node_modules /usr/local/julia* /opt/mssql-tools /etc/skel /usr/share/vim /usr/share/postgresql /usr/share/man /usr/share/apache-maven-*
sudo rm -rf /usr/share/R /usr/share/alsa /usr/share/miniconda /usr/share/grub /usr/share/gradle-* /usr/share/locale /usr/share/texinfo /usr/share/kotlinc /usr/share/swift
sudo rm -rf /usr/share/doc /usr/share/az_9.3.0 /usr/share/sbt /usr/share/ri /usr/share/icons /usr/share/java /usr/share/fonts /usr/lib/google-cloud-sdk /usr/lib/jvm
sudo rm -rf /usr/lib/mono /usr/lib/R /usr/lib/postgresql /usr/lib/heroku /usr/lib/gcc
