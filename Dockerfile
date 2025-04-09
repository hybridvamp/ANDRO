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

# Download and extract ANDRO
RUN wget https://github.com/AryanVBW/ANDRO/releases/download/v.1.0/ANDRO.zip \
    && unzip ANDRO.zip \
    && rm ANDRO.zip

# Change working directory to the ANDRO folder
WORKDIR /app/ANDRO

# Install dependencies
RUN npm install

# Set default port for ANDRO
EXPOSE 3456

# Setup entrypoint script to handle configuration and startup
RUN echo '#!/bin/bash\n\
# Check if username/password environment variables are provided\n\
if [ ! -z "$ANDRO_USERNAME" ] && [ ! -z "$ANDRO_PASSWORD" ]; then\n\
  echo "Setting up custom credentials..."\n\
  # Convert password to MD5 hash (ensure lowercase)\n\
  PASSWORD_HASH=$(echo -n "$ANDRO_PASSWORD" | md5sum | awk "{print \\$1}" | tr "[:upper:]" "[:lower:]")\n\
  # Update maindb.json with provided credentials\n\
  sed -i "s/\"username\":.*,/\"username\": \"$ANDRO_USERNAME\",/" maindb.json\n\
  sed -i "s/\"password\":.*,/\"password\": \"$PASSWORD_HASH\",/" maindb.json\n\
  echo "Credentials updated."\n\
fi\n\
\n\
# Configure PM2 to keep the application running\n\
pm2 start index.js\n\
# Save the PM2 process list and corresponding environments\n\
pm2 save\n\
# Configure PM2 to start on system boot\n\
pm2 startup\n\
# Keep container running\n\
echo "ANDRO is now running on port 3456"\n\
# Use PM2 in no-daemon mode as the main process to keep container running\n\
exec pm2 logs --no-daemon' > /app/ANDRO/entrypoint.sh \
    && chmod +x /app/ANDRO/entrypoint.sh

# Set environment variables with the requested credentials
ENV ANDRO_USERNAME=hybrid
ENV ANDRO_PASSWORD=hybrid

# Run entrypoint script
ENTRYPOINT ["/app/ANDRO/entrypoint.sh"]