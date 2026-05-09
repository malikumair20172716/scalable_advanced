# Stage 1: Build the React Application
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Build the project
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Install gettext for envsubst (needed for runtime env injection)
RUN apk add --no-cache gettext

# Copy build files from the build stage
# Note: If your project uses Vite, change 'build' to 'dist'
COPY --from=build /app/build /usr/share/nginx/html

# Replace default nginx config with our custom one
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script that injects env variables at runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 80
EXPOSE 80

# Use entrypoint to inject env vars before starting nginx
CMD ["/entrypoint.sh"]
