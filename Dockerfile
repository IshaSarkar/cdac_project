FROM python:3.10-slim
WORKDIR /app
COPY app/ /app
RUN pip install flask
EXPOSE 5000
CMD ["python", "app.py"]
