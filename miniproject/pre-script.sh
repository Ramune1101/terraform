#!/bin/bash

echo -n "Enter yout key filename"
read SSHKEYFILE

ssh-keygen -t rsa -f ~/.ssh/$SSHKEYFILE -n ''
