#!/bin/bash

if [ ! -d "/home/${USER}/data" ]; then
    mkdir -p ~/data/mariadb
    mkdir -p ~/data/wordpress
fi
