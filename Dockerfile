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
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 16.x
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install PM2 globally
RUN npm install pm2 -g

# Create app directory
WORKDIR /app

# Download and extract ANDRO
RUN wget https://github.com/AryanVBW/ANDRO/releases/download/v.1.0/ANDRO.zip \
    && unzip ANDRO.zip \
    && rm ANDRO.zip

# IMPORTANT: Removed "npm install" as there's no package.json in the project
# The installation steps indicate that PM2 is the only Node.js dependency needed

# Set default port for ANDRO
EXPOSE 8080

# Install md5sum if not already included
RUN apt-get update && apt-get install -y \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Setup entrypoint script to handle configuration and startup
RUN echo '#!/bin/bash\n\
# Check if username/password environment variables are provided\n\
if [ ! -z "$ANDRO_USERNAME" ] && [ ! -z "$ANDRO_PASSWORD" ]; then\n\
  echo "Setting up custom credentials..."\n\
  # Convert password to MD5 hash\n\
  PASSWORD_HASH=$(echo -n "$ANDRO_PASSWORD" | md5sum | awk "{print \\$1}")\n\
  # Update maindb.json with provided credentials\n\
  sed -i "s/\"username\":.*,/\"username\": \"$ANDRO_USERNAME\",/" maindb.json\n\
  sed -i "s/\"password\":.*,/\"password\": \"$PASSWORD_HASH\",/" maindb.json\n\
  echo "Credentials updated."\n\
fi\n\
\n\
# Start ANDRO with PM2\n\
pm2 start index.js --no-daemon' > /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh

# Set environment variables with the requested credentials
ENV ANDRO_USERNAME=hybrid
ENV ANDRO_PASSWORD=hybrid

# Run entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]