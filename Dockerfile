FROM node:18.16.0-alpine AS BASEIMAGE

WORKDIR /src
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run prebuild && npm run build && npm prune --production

FROM node:18.16.0-alpine

WORKDIR /src
ENV TZ=Asia/Jakarta

COPY --from=BASEIMAGE /src/dist /src/dist
COPY --from=BASEIMAGE /src/node_modules /src/node_modules
EXPOSE 3000

CMD ["node", "dist/main.js"]
