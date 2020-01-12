#!/bin/bash
docker build -t myapp .
docker tag myapp:latest 821731102189.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker push 821731102189.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
