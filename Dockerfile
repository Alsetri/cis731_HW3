# ==============================================================================
# CIS 531/731: DevContainer Dockerfile (MP2)
# Base image is a build arg (CIS 731 extension): CPU default, CUDA on GPU hosts.
# Moved bullseye -> bookworm: Debian 11 is EOL and its packages now 404.
# ==============================================================================
ARG BASE_IMAGE=python:3.10-slim-bookworm
FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG DEBIAN_FRONTEND=noninteractive
LABEL mp2.base_image="${BASE_IMAGE}"

# 1. Install System Dependencies (Java for PySpark, FFmpeg for Whisper)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    openjdk-17-jre-headless \
    ffmpeg \
    git \
    sudo \
    ca-certificates \
    && if ! command -v python3 >/dev/null 2>&1; then \
         apt-get install -y --no-install-recommends python3 python3-pip python3-venv; \
       fi \
    && rm -rf /var/lib/apt/lists/*

# 2. Configure Environment Variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PYSPARK_PYTHON=python3
ENV PIP_NO_CACHE_DIR=1

# 3. Install Python Dependencies (Strict Pinned Versions per MP2 Manifest)
#    numpy is pinned because torch 2.2.1 and faiss-cpu 1.8.0 are built against
#    the NumPy 1.x ABI; NumPy 2.x breaks both imports in verify_env.py.
# 3. Install Python Dependencies (Strict Pinned Versions per MP2 Manifest)
#    pip/setuptools pinned: openai-whisper 20231117's setup.py needs pkg_resources.
#    numpy pinned: torch 2.2.1 / faiss-cpu 1.8.0 use the NumPy 1.x ABI.
#    sentence-transformers added for MP3 Lab 3b; manifest versions restated so
#    pip cannot upgrade transformers out from under them.
RUN python3 -m pip install --upgrade \
    "pip==24.0" \
    "setuptools==69.5.1" \
    "wheel==0.43.0" \
 && python3 -m pip install \
    pyspark==3.5.1 \
    torch==2.2.1 \
    transformers==4.38.2 \
    mlflow==2.11.1 \
    faiss-cpu==1.8.0 \
    numpy==1.26.4 \
    sentence-transformers==2.6.1 \
    jupyterlab \
    ipykernel \
 && python3 -m pip install --no-build-isolation \
    openai-whisper==20231117

# 4. Create Non-Root User (Required for standard DevContainer permissions)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /workspace