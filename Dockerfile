# Base image with Ubuntu
FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    openjdk-8-jre \
    gnupg \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 16.x
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install PM2 globally
RUN npm install pm2 -g

# Create app directory
WORKDIR /app

# Download and extract ANDRO (using v.2.0 from the script rather than v.1.0)
RUN wget https://github.com/AryanVBW/ANDRO/releases/download/v.2.0/ANDRO.zip \
    && unzip ANDRO.zip \
    && rm ANDRO.zip

# Change working directory to the ANDRO folder
WORKDIR /app/ANDRO

# Install dependencies
RUN npm install

# Set default port based on the script
EXPOSE 8789

# Create a health check for the container
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8789 || exit 1

# Setup entrypoint script to handle configuration and startup
RUN echo '#!/bin/bash\n\
\n\
# Function to log actions\n\
log() {\n\
    echo -e "\\033[0;32m[*]\\033[0m $1"\n\
}\n\
\n\
# Function to log errors\n\
error() {\n\
    echo -e "\\033[0;31m[!] ERROR: $1\\033[0m" >&2\n\
}\n\
\n\
# Check if username/password environment variables are provided\n\
if [ ! -z "$ANDRO_USERNAME" ] && [ ! -z "$ANDRO_PASSWORD" ]; then\n\
  log "Setting up custom credentials..."\n\
  # Convert password to MD5 hash (ensure lowercase)\n\
  PASSWORD_HASH=$(echo -n "$ANDRO_PASSWORD" | md5sum | awk "{print \\$1}" | tr "[:upper:]" "[:lower:]")\n\
  # Update maindb.json with provided credentials\n\
  sed -i "s/\"username\":.*,/\"username\": \"$ANDRO_USERNAME\",/" maindb.json\n\
  sed -i "s/\"password\":.*,/\"password\": \"$PASSWORD_HASH\",/" maindb.json\n\
  log "Credentials updated."\n\
fi\n\
\n\
# Configure PM2 to keep the application running\n\
log "Starting ANDRO application with PM2..."\n\
pm2 start index.js\n\
\n\
# Save the PM2 process list and corresponding environments\n\
pm2 save\n\
\n\
# Configure PM2 for automatic startup\n\
pm2 startup\n\
\n\
# Display access information\n\
echo -e "\\033[1;35mAccess ANDRO at:\\033[0m"\n\
echo -e "\\033[1;34mLocal URL: http://localhost:8789\\033[0m"\n\
echo -e "\\033[1;34mContainer IP URL: http://$(hostname -i):8789\\033[0m"\n\
echo -e "\\033[1;35mLogin credentials - Username: \\033[1;33m$ANDRO_USERNAME\\033[0m, Password: \\033[1;33m$ANDRO_PASSWORD\\033[0m"\n\
\n\
# Keep container running by watching logs\n\
log "ANDRO is now running on port 8789"\n\
exec pm2 logs --no-daemon' > /app/ANDRO/entrypoint.sh \
    && chmod +x /app/ANDRO/entrypoint.sh

# Set environment variables with the requested credentials
ENV ANDRO_USERNAME=hybrid
ENV ANDRO_PASSWORD=hybrid

# Run entrypoint script
ENTRYPOINT ["/app/ANDRO/entrypoint.sh"]