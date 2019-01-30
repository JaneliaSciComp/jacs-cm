FROM python:3.6.8-alpine3.8

RUN apk update && apk upgrade && \
    apk add --no-cache bash git uwsgi-python3 \
        gcc libc-dev linux-headers py-virtualenv python3-dev pcre

WORKDIR /app
RUN git clone https://github.com/JaneliaSciComp/lightsheet-pipeline

WORKDIR /app/lightsheet-pipeline
RUN virtualenv --no-site-packages env
WORKDIR /app/lightsheet-pipeline/lightsheetInterface
RUN /app/lightsheet-pipeline/env/bin/pip install -r requirements.txt

COPY ipp.ini /app
COPY start.sh /app

EXPOSE 8000
CMD [ "sh", "/app/start.sh" ]

#CMD [ "uwsgi", "--ini", "/app/ipp.ini", \
#               "--uid", "uwsgi", \
#               "--plugins", "python3", \
#               "--protocol", "uwsgi", \
#               "--wsgi", "main:application" ]



