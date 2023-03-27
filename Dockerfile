# Run the following command in the adaptive-lighting repo folder to run the tests:
# docker run -v $(pwd):/app adaptive-lighting

# Optionally build the image yourself with:
# docker build -t basnijholt/adaptive-lighting:latest .

FROM python:3.11-buster

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone home-assistant/core
RUN git clone https://github.com/home-assistant/core.git /core

# Install home-assistant/core dependencies
RUN pip3 install -r /core/requirements.txt --use-pep517 && \
    pip3 install -r /core/requirements_test.txt --use-pep517 && \
    pip3 install -e /core/ --use-pep517

# Clone the Adaptive Lighting repository
RUN git clone https://github.com/basnijholt/adaptive-lighting.git /app

# Setup symlinks in core
RUN ln -s /app/custom_components/adaptive_lighting /core/homeassistant/components/adaptive_lighting && \
    ln -s /app/tests /core/tests/components/adaptive_lighting && \
    # For test_dependencies.py
    ln -s /core /app/core

# Install dependencies of components that Adaptive Lighting depends on
RUN pip3 install $(python3 /app/test_dependencies.py) --use-pep517

WORKDIR /core

CMD ["python3", "-X", "dev", "-m", "pytest", "-qq", "--timeout=9", "--durations=10", "--cov='homeassistant'", "--cov-report=xml", "-o", "console_output_style=count", "tests/components/adaptive_lighting"]
