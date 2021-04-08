FROM python:3.9.4-alpine3.12

WORKDIR /app

COPY src/. .

RUN adduser -D speedtest
RUN apk --no-cache add uwsgi-python3 python3-dev build-base linux-headers pcre-dev
RUN pip install uwsgi && \
    pip install -r requirements.txt && \
    export ARCHITECTURE=$(uname -m) && \
    if [ "$ARCHITECTURE" == 'armv7l' ]; then export ARCHITECTURE=arm; fi && \
    wget -O /tmp/speedtest.tgz "https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-${ARCHITECTURE}-linux.tgz" && \
    tar zxvf /tmp/speedtest.tgz -C /tmp && \
    cp /tmp/speedtest /usr/local/bin && \
    rm requirements.txt

RUN chown -R speedtest:speedtest /app

RUN apk del --purge python3-dev \ 
    build-base \
    linux-headers \
    pcre-dev && rm -rf \
	/root/.cache \
    /tmp/*

USER speedtest

CMD uwsgi --http :${SPEEDTEST_PORT:=9798} --plugin python --wsgi-file exporter.py --callable app

HEALTHCHECK --timeout=10s CMD wget --no-verbose --tries=1 --spider http://localhost:${SPEEDTEST_PORT:=9798}/