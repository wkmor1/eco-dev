#!/bin/bash

USERID=${USERID:=1000}
ROOT=${ROOT:=FALSE}
export HOME=/home/$USER

# Add user
useradd -u $USERID $USER
addgroup $USER staff
echo "$USER:$PASSWORD" | chpasswd
mkdir -p $HOME/.jupyter/
mv jupyter_notebook_config.py $_

## Configure git for the User. Since root is running this script, cannot use `git config`
echo -e "[user]\n\tname = $USER\n\temail = $EMAIL\n\n[credential]\n\thelper = cache\n" > $HOME/.gitconfig

# Use Env flag to know if user should be added to sudoers
if [ "$ROOT" == "TRUE" ]
        then
                adduser $USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
fi

env | cat >> /etc/R/Renviron

chown -R $USER:$USER $HOME
