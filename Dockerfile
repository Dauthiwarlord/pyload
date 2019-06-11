# Highly-Optimized Docker Image of pyLoad (debian-slim variant)
# AUTHOR: vuolter


ARG PYTHON_VERSION=3.7

FROM python:${PYTHON_VERSION}-slim as base

RUN echo "deb http://deb.debian.org/debian stable main contrib non-free" | tee -a /etc/apt/sources.list.d/docker.list && \
    echo "deb-src http://deb.debian.org/debian stable main contrib non-free" | tee -a /etc/apt/sources.list.d/docker.list




FROM base as wheels_builder

COPY setup.cfg /source/setup.cfg
WORKDIR /wheels

RUN python -c "import configparser as cp; c = cp.ConfigParser(); c.read('/source/setup.cfg'); print(c['options']['install_requires'] + c['options.extras_require']['extra'])" | xargs pip wheel --wheel-dir=.




FROM base as source_builder

COPY . /source
WORKDIR /source

RUN pip install --no-cache-dir --no-compile --upgrade Babel Jinja2 && \
    python setup.py build_locale




FROM base as package_installer

COPY --from=wheels_builder /wheels /wheels
COPY --from=source_builder /source /source
WORKDIR /package

RUN pip install --find-links=/wheels --no-cache-dir --no-compile --no-index --prefix=. /source[extra]




#### TEST ####

# FROM base as test

# LABEL version="1.0" \
#       description="The free and open-source Download Manager written in pure Python" \
#       maintainer="vuolter@gmail.com"

# ENV PYTHONUNBUFFERED=1

# COPY --from=wheels_builder /wheels /pyload/dist/wheels
# COPY --from=source_builder /source /pyload
# WORKDIR /opt/pyload

# RUN mkdir profile tmp downloads && \
#     apt-get update && \
#     apt-get install --no-install-recommends -y tesseract-ocr unrar && \
#     rm -rf /var/lib/apt/lists/* && \
#     pip install --no-cache-dir --no-compile --no-index --find-links=/pyload/dist/wheels -e /pyload[extra]

# VOLUME ["/opt/pyload"]
# EXPOSE 8000 7227 9666
# USER guest

# ENTRYPOINT ["pyload"]

#### TEST ####




FROM base

LABEL version="1.0" \
      description="The free and open-source Download Manager written in pure Python" \
      maintainer="vuolter@gmail.com"

ENV PYTHONUNBUFFERED=1

COPY --from=package_installer /package /usr/local
WORKDIR /opt/pyload

RUN mkdir profile tmp downloads && \
    apt-get update && \
    apt-get install --no-install-recommends -y tesseract-ocr unrar && \
    rm -rf /var/lib/apt/lists/*

VOLUME ["/opt/pyload"]
EXPOSE 8000 9666
USER guest

ENTRYPOINT ["pyload"]
CMD ["--userdir", "/opt/pyload/profile", "--cachedir", "/opt/pyload/tmp", "--storagedir", "/opt/pyload/downloads"]