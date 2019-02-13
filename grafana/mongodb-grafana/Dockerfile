FROM node:8-jessie

WORKDIR /usr/src/app

COPY . .

RUN npm install 

RUN npm run build

EXPOSE 3333

CMD [ "npm", "run", "server" ]
