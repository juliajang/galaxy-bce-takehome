# Build stage
FROM python:3.10-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt

RUN pip wheel --wheel-dir=/wheels -r /app/requirements.txt


# Final stage
FROM python:3.10-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8080
ENV GUNICORN_WORKERS=3
ENV GUNICORN_THREADS=2

# non-root user setup
RUN addgroup --system appgroup && adduser --system --group appuser

WORKDIR /app

# for reproducible builds
COPY --from=builder /wheels /wheels
COPY --from=builder /app/requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --no-index --find-links=/wheels -r /app/requirements.txt

COPY . /app

# non-root user as owner
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers ${GUNICORN_WORKERS} --threads ${GUNICORN_THREADS} app:app"]