# base node image
FROM node:lts-alpine AS base

# set for base and all layer that inherit from it
ENV NODE_ENV=production

# Install openssl for Prisma
# RUN apk -U add --update-cache openssl sqlite

# Create user and set ownership and permissions as required
RUN apk add --no-cache bash && \
    addgroup student && \
    adduser -D -H -g "student" -G student student && \
    mkdir /cst8918-lab1 && \
    chown -R student:student /cst8918-lab1

# Install all node_modules, including dev dependencies
FROM base AS deps

WORKDIR /cst8918-lab1

ADD package.json ./
RUN npm install --include=dev

# Setup production node_modules
FROM base AS production-deps

WORKDIR /cst8918-lab1

COPY --from=deps /cst8918-lab1/node_modules /cst8918-lab1/node_modules
ADD package.json ./
RUN npm prune --omit=dev

# Build the app
FROM base AS build

WORKDIR /cst8918-lab1

COPY --from=deps /cst8918-lab1/node_modules /cst8918-lab1/node_modules

ADD . .
RUN npm run build

# Finally, build the production image with minimal footprint
FROM base

ENV PORT=8080
ENV NODE_ENV=production
# BONUS: This should be injected at runtime from a secrets manager
# We will review the solution next class
# ENV WEATHER_API_KEY="bc2682b67f497cf9a1f5bfbdde7a4ea1"

WORKDIR /cst8918-lab1

COPY --from=production-deps /cst8918-lab1/node_modules /cst8918-lab1/node_modules

COPY --from=build /cst8918-lab1/build /cst8918-lab1/build
COPY --from=build /cst8918-lab1/public /cst8918-lab1/public
COPY --from=build /cst8918-lab1/package.json /cst8918-lab1/package.json

RUN chown -R student:student /cst8918-lab1
USER student
CMD [ "/bin/sh", "-c", "./node_modules/.bin/remix-serve ./build/index.js" ]
