
# BASIC NODE IMAGE ------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# base image
# ----------------------------------
# FROM node:14.14.0-alpine

# expose port
# ----------------------------------
# EXPOSE 3000

# create the working directory
# ----------------------------------
# WORKDIR /socket

# copy in the package.json and package lock
# good practice to just copy in these files first before running npm install
# This way every time a source file changes we are not running npm install every time and only running npm install when the package.json / package-lock changes
# The * means copy it there but dont if its not
# ./ means copy it into the current working directory
# ----------------------------------
# COPY package.json package-lock*.json ./

# run the npm install and then clean up
# ----------------------------------
# RUN npm install && npm cache clean --force

# copy in everything else from the host directory to the current working directory of the image
# copy the current directory into the docker container root directory
# ----------------------------------
# COPY . .

# run the command to start the server
# ----------------------------------
# CMD ["node", "dist/index.js"]

# Node process management in containers

# SIGINT/SIGTERM allow for a graceful stop. 
# NPM does not respond to these. Node can listen to these so we can capture the signal and run functions we need for cleanup before we stop the container

# if your container takes a while to shut down after a ctrl c it is because it cant shut down so it is forced to do a SIGKILL. 
# docker run --init -d nodeapp. This will wrap your node commands with PID1 so it can handle ctrl c

# NODE IMAGE WITH GRACEFUL SHUTDOWN ---------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# ----------------------------------
# FROM node:14.14.0-alpine

# ----------------------------------
# EXPOSE 3000

# https://github.com/krallin/tini#alpine-linux-package
# want to run apk before copy any packages in
# ----------------------------------
# RUN apk add --no-cache tini

# ----------------------------------
# WORKDIR /socket

# ----------------------------------
# COPY package.json package-lock*.json ./

# ----------------------------------
# RUN npm install && npm cache clean --force

# ----------------------------------
# COPY . .

# pid stands for process ID. Every process running on the system is given a unique ID. The process with ID 1 is the init process.
# Basically the init process acts as the ancestor to all the processes that are further started.
# This process is responsible for starting all other background processes on the system once it is turned on.
# an entry point is the command we run when we build the docker container ie: docker run --init -d nodeapp (the --init is the entrypoint)
# Tini now becomes the PID1 (process that runs all sub processes)
# ENTRYPOINT ["executable", "param1", "param2"]
# having the entrypoint hear means we dont have to run our containers with the --init tag
# Now when we shut down our container using ctrc c, the container will shutdown gracefully
# ----------------------------------
# ENTRYPOINT ["/sbin/tini", "--"]

# ----------------------------------
# CMD ["node", "dist/index.js"]

# ADVANCED DOCKER FILES WITH MULIT-STAGE AND BUILDKIT ---------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# artifact only - the minimum stuff you need for production

# --target allows us to target a specific stage in our dockerfile
# docker build -t <tag name> --target prod .

# --- PRODUCTION: docker build -t production --target prod . --- 
FROM node:14.14.0-alpine as prod

ENV NODE_ENV=production

EXPOSE 3000

RUN apk add --no-cache tini

WORKDIR /sockets

ENV PATH /sockets/node_modules/:bin/:$PATH

COPY package*.json ./

# only install production dependencies and ignores devopment dependencies 
RUN npm install --only=production && npm cache clean --force

# NOTE copy will only copy the files inside the directory so we have to reassign them to another directory
COPY dist ./dist

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["node", "dist/index.js"]

# --- DEVELOPMENT ---
FROM prod as dev 

ENV NODE_ENV=development

# we have already installed dev dependencies above so now we install the development ones only. No need to worry about cash because we wont be putting on a server
RUN npm install --only=development

COPY . .

CMD ["npm", "start"]










