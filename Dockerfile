FROM node:6
MAINTAINER arthur@arthursilber.de

COPY ./* /app/
WORKDIR /app

RUN npm install

ENTRYPOINT ["node", "index.js"]