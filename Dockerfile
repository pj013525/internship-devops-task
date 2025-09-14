# Dockerfile - Node.js sample app (multi-stage)
FROM node:18-alpine AS build

WORKDIR /app

# copy package files first for caching
COPY package*.json ./
RUN npm ci --only=production

# Copy the code
COPY . .

# run build/test if any
RUN if [ -f package-lock.json ]; then echo "packages installed"; fi

# final image
FROM node:18-alpine AS runtime
WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build /app /app

# expose and run as non-root
EXPOSE 3000
USER appuser

# start app (adjust if your app uses `npm start`)
CMD ["npm", "start"]
