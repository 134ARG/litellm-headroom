FROM ghcr.io/berriai/litellm:main-latest

USER root

# Install headroom (no torch needed for LiteLLM callback)
RUN pip install --no-cache-dir headroom-ai

# Copy custom entrypoint that registers the Headroom callback
# then delegates to the standard litellm CLI
COPY start_litellm.py /app/start_litellm.py

EXPOSE 4000/tcp

ENTRYPOINT ["python", "/app/start_litellm.py"]
CMD ["--config", "/app/config.yaml", "--port", "4000"]
