FROM --platform=linux/arm64 ubuntu:20.04

# Avoid timezone prompt
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    sudo \
    openjdk-11-jdk \
    wget \
    cmake \
    ninja-build \
    pkg-config \
    ruby-full \
    ruby-bundler \
    libstdc++6 \
    libpulse0 \
    libglu1-mesa \
    ca-certificates \
    clang \
    libgtk-3-dev \
    liblzma-dev \
    chromium-browser \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -ms /bin/bash developer
RUN adduser developer sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure git
RUN git config --system http.postBuffer 524288000
RUN git config --system http.maxRequestBuffer 524288000
RUN git config --system core.compression 9
RUN git config --system https.maxRequestBuffer 524288000

# Install Android SDK
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

# Download SDK tools
RUN mkdir -p ${ANDROID_SDK_ROOT} && \
    cd ${ANDROID_SDK_ROOT} && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip && \
    unzip -q commandlinetools-linux-*_latest.zip && \
    rm commandlinetools-linux-*_latest.zip && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/bin ${ANDROID_SDK_ROOT}/cmdline-tools/latest/ && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/lib ${ANDROID_SDK_ROOT}/cmdline-tools/latest/

# Set correct permissions
RUN chown -R developer:developer ${ANDROID_SDK_ROOT}
RUN chmod -R a+x ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/*

# Switch to developer user
USER developer

# Set up Chrome for web development
ENV CHROME_EXECUTABLE=/usr/bin/chromium-browser

# Accept licenses and install Android SDK packages
RUN yes | sdkmanager --licenses && \
    sdkmanager --install \
    "platforms;android-33" \
    "build-tools;33.0.0" \
    "extras;android;m2repository" \
    "extras;google;m2repository"

# Set up Flutter
ENV FLUTTER_HOME=/home/developer/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

# Install Flutter
RUN git clone --branch stable https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Set Flutter permissions
RUN chown -R developer:developer ${FLUTTER_HOME}

# Initialize Flutter
RUN cd ${FLUTTER_HOME} && \
    flutter channel stable && \
    flutter upgrade && \
    flutter config --no-analytics && \
    flutter config --enable-android --enable-ios && \
    flutter config --enable-linux-desktop && \
    flutter precache

# Create startup script
RUN echo '#!/bin/bash\n\
export ADB_SERVER_SOCKET=tcp:host.docker.internal:5037\n\
exec "$@"' > /home/developer/entrypoint.sh && \
    chmod +x /home/developer/entrypoint.sh

# Set up working directory
WORKDIR /home/developer/app

# Copy the Flutter project files
COPY --chown=developer:developer . .

# Get Flutter dependencies
RUN flutter pub get