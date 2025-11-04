FROM python:3.13.9-alpine3.22
ARG GIT_BRANCH=dev
ARG GIT_COMMIT=8e07d1b

RUN apk update && apk upgrade && \
    apk add --no-cache pcre pcre-dev && \
    apk add --no-cache bash git uwsgi-python3 python3 \
    gcc libc-dev linux-headers

WORKDIR /app/lightsheet-pipeline

RUN git clone -b ${GIT_BRANCH} https://github.com/JaneliaSciComp/image_processing_pipeline.git . \
 && git reset --hard ${GIT_COMMIT}

WORKDIR /app/lightsheet-pipeline/lightsheetInterface

RUN pip3 install --upgrade pip \
 && pip3 install --no-cache-dir -r requirements.txt \
 && echo ${GIT_COMMIT} > .git_commit

COPY ipp.ini /app
COPY start.sh /app

EXPOSE 8000

CMD [ "uwsgi", \
    "--ini", "/app/ipp.ini", \
    "--uid", "uwsgi" ]
