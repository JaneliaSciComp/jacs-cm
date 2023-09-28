FROM python:3.8.18-alpine3.18

RUN apk update && apk upgrade && \
    apk add --no-cache pcre pcre-dev && \
    apk add --no-cache bash git uwsgi-python3 python3 \
    gcc libc-dev linux-headers

WORKDIR /app
RUN git clone https://github.com/JaneliaSciComp/lightsheet-pipeline

WORKDIR /app/lightsheet-pipeline/lightsheetInterface
COPY requirements.txt .

RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.txt

COPY ipp.ini /app
COPY start.sh /app

EXPOSE 8000

CMD [ "uwsgi", \
    "--ini", "/app/ipp.ini", \
    "--uid", "uwsgi" ]

