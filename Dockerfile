FROM node:4.6
WORKDIR /app
ADD . /appRUN npm install
EXPOSE 3000
CMD npm start
