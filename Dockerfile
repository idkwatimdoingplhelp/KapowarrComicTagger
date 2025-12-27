# Use lsiobase Debian bookworm image
FROM lsiobase/debian:bookworm

STOPSIGNAL SIGTERM

# Install Python 3.11 + pip + build dependencies for pyicu and other packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-dev \
        python3-pip \
        build-essential \
        g++ \
        pkg-config \
        libicu-dev \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3.11 -m pip install --no-cache-dir --upgrade pip --break-system-packages

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt requirements.txt
RUN python3.11 -m pip install --break-system-packages --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set permissions
RUN \
    chown -R abc:abc /app \
    && chmod -R 755 /app

# Expose port and set environment
EXPOSE 5656
ENV PUID=1000 \
    PGID=1000 \
    TZ=UTC

# Set up s6 service for Kapowarr
RUN \
    mkdir -p /etc/services.d/kapowarr \
    && echo "#!/usr/bin/with-contenv bash\nexec s6-setuidgid abc python3.11 /app/Kapowarr.py" \
        > /etc/services.d/kapowarr/run \
    && chmod +x /etc/services.d/kapowarr/run
