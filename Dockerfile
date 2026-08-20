# syntax=docker/dockerfile:1

FROM node:22-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
# Start the todo application.
CMD ["node", "src/index.js"]
EXPOSE 3000
