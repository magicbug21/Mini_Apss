FROM python:3.12-slim

WORKDIR /app
COPY static/ ./static/

EXPOSE 8000

CMD ["python", "-m", "http.server", "8000", "--directory", "/app/static"]
