FROM docker.io/python:3.7-alpine
WORKDIR /app

COPY ./demo/flask-web .

ENV FLASK_APP=./app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=80

RUN apk add --no-cache gcc musl-dev linux-headers
RUN pip install -r requirements.txt

EXPOSE 8080
#EXPOSE 5000
CMD ["flask", "run"]
