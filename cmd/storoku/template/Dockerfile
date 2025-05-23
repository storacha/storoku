# syntax=docker.io/docker/dockerfile:1

{{with .JS}}
FROM node:22-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi


# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
COPY ./deploy/.env.production.local ./.env.production.local

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED=1

{{if .Next}}
RUN \
  if [ -f yarn.lock ]; then yarn run build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm run build; \
  else echo "Lockfile not found." && exit 1; \
  fi
{{else}}
RUN \
  npx @vercel/ncc build {{.EntryPoint}} -o build/{{.EntryPoint.OutputDir}}
{{end}}

{{range .Scripts}}
RUN \
  npx @vercel/ncc build {{.Script}} -o build/{{.Script.OutputDir}}
{{end}}

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY --from=builder /app/public ./public
{{if .Next}}
# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nodejs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nodejs:nodejs /app/.next/static ./.next/static
{{else}}
COPY --from=builder --chown=nodejs:nodejs /app/build/{{.EntryPoint.OutputDir}} ./{{.EntryPoint.OutputDir}}
{{end}}{{range .Scripts}}COPY --from=builder --chown=nodejs:nodejs /app/build/{{.Script.OutputDir}} {{.Script.OutputDir}}
{{end}}
USER nodejs
{{end}}

EXPOSE {{if .Port}}{{.Port}}{{else}}8080{{end}}

ENV PORT={{if .Port}}{{.Port}}{{else}}8080{{end}}
{{with .JS}}
# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
ENV HOSTNAME="0.0.0.0"
CMD ["node", {{if .Next}}"server.js"{{else}}"{{.EntryPoint.Command}}"{{end}}]
{{end}}