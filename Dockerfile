FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    openjdk-8-jre \
    gnupg \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install pm2 -g

WORKDIR /app

RUN wget https://github.com/AryanVBW/ANDRO/releases/download/v.1.0/ANDRO.zip \
    && unzip ANDRO.zip \
    && rm ANDRO.zip

WORKDIR /app/ANDRO

RUN npm install

EXPOSE 3456

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
# Start ANDRO with PM2\n\
pm2 start index.js --no-daemon' > /app/ANDRO/entrypoint.sh \
    && chmod +x /app/ANDRO/entrypoint.sh

ENV ANDRO_USERNAME=hybrid
ENV ANDRO_PASSWORD=hybrid

ENTRYPOINT ["/app/ANDRO/entrypoint.sh"]