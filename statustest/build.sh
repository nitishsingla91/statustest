#!/bin/sh
mvn clean install
docker build -t nsingla85/statustest .