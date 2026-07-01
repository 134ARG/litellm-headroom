FROM ghcr.io/xinlong-wu/litellm-all-in-one:latest

USER root

# Install headroom (no torch needed for LiteLLM callback)
# RUN uv pip install --no-cache-dir ast-grep-cli==0.42.3 && \
#     uv pip install --no-cache-dir --no-deps headroom-ai==0.22.3

# Copy custom entrypoint that registers the Headroom callback
# then delegates to the standard litellm CLI
COPY start_litellm.py /app/start_litellm.py

EXPOSE 4000/tcp

ENTRYPOINT ["python", "/app/start_litellm.py"]
CMD ["--config", "/app/config.yaml", "--log_dir", "/app/logs", "--port", "4000"]
