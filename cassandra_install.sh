#!/bin/bash

sudo apt update && apt install openjdk-8-jdk apt-transport-https -y;

sudo apt install apt-transport-https -y;

wget -q -O - https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -;

sudo sh -c 'echo "deb http://www.apache.org/dist/cassandra/debian 311x main" > /etc/apt/sources.list.d/cassandra.list';

sudo apt update && sudo apt install cassandra -y;
