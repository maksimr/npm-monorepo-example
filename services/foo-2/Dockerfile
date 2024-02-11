FROM node:20-alpine as base

FROM base as builder
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
RUN apk update
WORKDIR /app
COPY . .
RUN npx -y turbo prune foo-2 --docker

FROM base AS installer
RUN apk add --no-cache libc6-compat
RUN apk update
WORKDIR /app

COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/package-lock.json ./package-lock.json
RUN npm ci

COPY --from=builder /app/out/full/ .
RUN npm run build --if-present

FROM base AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 app
RUN adduser --system --uid 1001 app
USER app
COPY --from=installer /app .
CMD node services/foo-2/dist/index.js
