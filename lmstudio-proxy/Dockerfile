FROM python:3.12-slim
RUN pip install --no-cache-dir aiohttp
WORKDIR /app
COPY proxy.py .
CMD ["python", "proxy.py"]
