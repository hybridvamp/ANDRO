# Use Ubuntu as the base image
FROM ubuntu:20.04

# Disable interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    unzip \
    wget \
    openjdk-8-jre \
    curl \
    bash \
    && apt-get clean

# Create working directory
WORKDIR /app

# Copy your script into the container
COPY script.sh .

# Make the script executable
RUN chmod +x script.sh

# Expose your desired port
EXPOSE 8789

# Run the script
CMD ["./script.sh"]
