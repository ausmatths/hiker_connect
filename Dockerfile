FROM --platform=linux/amd64 ubuntu:20.04

# Set environment variables
ENV TZ="UTC" \
    DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    ANDROID_SDK_ROOT="/opt/android-sdk" \
    ANDROID_HOME="/opt/android-sdk" \
    FLUTTER_HOME="/home/developer/flutter" \
    PATH="/home/developer/flutter/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin:${PATH}"

# Set timezone and install dependencies
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    sudo \
    wget \
    cmake \
    ninja-build \
    pkg-config \
    libstdc++6 \
    libpulse0 \
    libglu1-mesa \
    ca-certificates \
    clang \
    libgtk-3-dev \
    usbutils \
    socat \
    locales \
    fonts-liberation \
    gpg \
    gpg-agent \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

# Install JDK 17
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - && \
    echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends temurin-17-jdk && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME="/usr/lib/jvm/temurin-17-jdk-amd64"
ENV PATH="$JAVA_HOME/bin:$PATH"

# Create a non-root user and setup permissions
RUN useradd -ms /bin/bash developer && \
    adduser developer sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    chown -R developer:developer /opt/android-sdk

# Switch to developer user
USER developer

# Download and setup Android SDK
RUN cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip && \
    unzip -q commandlinetools-linux-*_latest.zip && \
    rm commandlinetools-linux-*_latest.zip && \
    mv cmdline-tools latest

# Explicitly download and install platform-tools for Linux
RUN cd ${ANDROID_SDK_ROOT} && \
    wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip && \
    unzip -q platform-tools-latest-linux.zip && \
    rm platform-tools-latest-linux.zip && \
    chmod +x ${ANDROID_SDK_ROOT}/platform-tools/adb

# Switch back to root user temporarily
USER root

# Install additional dependencies for ADB
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libc6 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Switch back to developer user
USER developer

# Verify ADB installation
RUN ${ANDROID_SDK_ROOT}/platform-tools/adb version || true

# Download and setup Flutter
RUN cd /home/developer && \
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz && \
    tar xf flutter_linux_3.27.3-stable.tar.xz && \
    rm flutter_linux_3.27.3-stable.tar.xz

# Install Android platform tools and accept licenses
RUN yes | JAVA_HOME=${JAVA_HOME} ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 || true && \
    JAVA_HOME=${JAVA_HOME} ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "platform-tools" \
    "build-tools;33.0.0" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "system-images;android-34;google_apis;x86_64"

# Configure Flutter
RUN flutter config --no-analytics && \
    flutter config --enable-android && \
    flutter precache && \
    git config --global --add safe.directory ${FLUTTER_HOME}

# Create entrypoint script
RUN echo '#!/bin/bash\n\
\n\
# Setup environment\n\
export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64\n\
export PATH=$JAVA_HOME/bin:$PATH\n\
\n\
# Verify environment\n\
for var in ANDROID_SDK_ROOT ANDROID_HOME FLUTTER_HOME JAVA_HOME; do\n\
    if [ -z "${!var}" ]; then\n\
        echo "Error: $var is not set"\n\
        exit 1\n\
    fi\n\
done\n\
\n\
# Wait for ADB socket\n\
for i in {1..30}; do\n\
    if [ -S /tmp/adb-5037 ]; then\n\
        echo "ADB socket found"\n\
        break\n\
    fi\n\
    echo "Waiting for ADB socket... ($i/30)"\n\
    sleep 1\n\
done\n\
\n\
# Configure ADB\n\
if [ -S /tmp/adb-5037 ]; then\n\
    export ADB_SERVER_SOCKET=unix:/tmp/adb-5037\n\
    echo "Using ADB socket at /tmp/adb-5037"\n\
fi\n\
\n\
# Print environment information\n\
echo "Environment:"\n\
echo "  Flutter: ${FLUTTER_HOME}"\n\
echo "  Android SDK: ${ANDROID_SDK_ROOT}"\n\
echo "  Java Home: ${JAVA_HOME}"\n\
\n\
# Print versions\n\
echo "Versions:"\n\
flutter --version\n\
dart --version\n\
java -version\n\
\n\
# Execute the provided command\n\
exec "$@"' > /home/developer/entrypoint.sh && \
    chmod +x /home/developer/entrypoint.sh

# Set working directory
WORKDIR /home/developer/app

# Set entrypoint and default command
ENTRYPOINT ["/home/developer/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]