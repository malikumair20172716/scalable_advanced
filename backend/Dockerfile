FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --only=production

COPY src ./src

EXPOSE 5000

ENV NODE_ENV=production

CMD ["npm", "start"]
