FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app /app

RUN pip install --upgrade pip && pip install -r requirements.txt

RUN mkdir -p /var/log/fastapi

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port 8000 --workers ${UVICORN_WORKERS:-2} --log-level ${UVICORN_LOG_LEVEL:-info} --proxy-headers"]
