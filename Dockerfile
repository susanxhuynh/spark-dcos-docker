# debian:9.3 - linux; amd64
# https://github.com/docker-library/repo-info/blob/master/repos/debian/tag-details.md#debian93---linux-amd64
FROM debian@sha256:02741df16aee1b81c4aaff4c48d75cc2c308bade918b22679df570c170feef7c

LABEL maintainer="Vishnu Mohan <vishnu@mesosphere.com>"

ARG CODENAME="stretch"
ARG CONDA_DIR="/opt/conda"
ARG CONDA_INSTALLER="Miniconda3-4.3.31-Linux-x86_64.sh"
ARG CONDA_MD5="7fe70b214bee1143e3e3f0467b71453c"
ARG CONDA_URL="https://repo.continuum.io/miniconda"
ARG DCOS_COMMONS_URL="https://downloads.mesosphere.com/dcos-commons"
ARG DCOS_COMMONS_VERSION="0.40.3"
ARG DISTRO="debian"
ENV DEBCONF_NONINTERACTIVE_SEEN="true"
ARG DEBIAN_FRONTEND="noninteractive"
ARG GPG_KEYSERVER="hkps://pgp.mit.edu"
ARG HADOOP_VERSION="2.7"
ARG JAVA_HOME="/opt/jdk"
ARG JAVA_URL="https://downloads.mesosphere.com/java"
ARG JAVA_VERSION="8u162"
ARG MESOSPHERE_PREFIX="/opt/mesosphere"
ARG LIBMESOS_BUNDLE_SHA256="875f6500101c7b219feebe05bd8ca68ea98682f974ca7f8efc14cb52790977b0"
ARG LIBMESOS_BUNDLE_URL="https://downloads.mesosphere.com/libmesos-bundle"
ARG LIBMESOS_BUNDLE_VERSION="master-28f8827"
ARG MESOS_JAR_SHA1="0cef8031567f2ef367e8b6424a94d518e76fb8dc"
ARG MESOS_MAVEN_URL="https://repository.apache.org/service/local/repositories/releases/content/org/apache/mesos/mesos"
ARG MESOS_PROTOBUF_JAR_SHA1="189ef74959049521be8f5a1c3de3921eb0117ffb"
ARG MESOS_SANDBOX="/mnt/mesos/sandbox"
ARG MESOS_VERSION="1.5.0"
ARG REPO="http://cdn-fastly.deb.debian.org"
ARG SPARK_DIST_URL="https://downloads.mesosphere.com/spark"
ARG SPARK_HOME="/opt/spark"
ARG SPARK_VERSION="2.2.1-1"
ARG VCS_REF
ARG VERSION

ENV CODENAME=${CODENAME:-"stretch"} \
    CONDA_DIR=${CONDA_DIR:-"/opt/conda"} \
    DEBCONF_NONINTERACTIVE_SEEN=${DEBCONF_NONINTERACTIVE_SEEN:-"true"} \
    DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-"noninteractive"} \
    DISTRO=${DISTRO:-"debian"} \
    GPG_KEYSERVER=${GPG_KEYSERVER:-"hkps://pgp.mit.edu"} \
    JAVA_HOME=${JAVA_HOME:-"/opt/jdk"} \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    MESOSPHERE_PREFIX=${MESOSPHERE_PREFIX:-"/opt/mesosphere}" \
    LIBPROCESS_SSL_CA_DIR="${MESOS_SANDBOX}/.ssl" \
    LIBPROCESS_SSL_CA_FILE="${MESOS_SANDBOX}.ssl/ca.crt" \
    LIBPROCESS_SSL_CERT_FILE="${MESOS_SANDBOX}/.ssl/scheduler.crt" \
    LIBPROCESS_SSL_KEY_FILE="${MESOS_SANDBOX}/.ssl/scheduler.key" \
    MESOS_AUTHENTICATEE="com_mesosphere_dcos_ClassicRPCAuthenticatee" \
    MESOS_MODULES="{\"libraries\": [{\"file\": \"libdcos_security.so\", \"modules\": [{\"name\": \"com_mesosphere_dcos_ClassicRPCAuthenticatee\"}]}]}" \
    MESOS_NATIVE_LIBRARY="${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so" \
    MESOS_NATIVE_JAVA_LIBRARY="${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so" \
    MESOS_SANDBOX=${MESOS_SANDBOX:-"/mnt/mesos/sandbox"} \
    PATH="${JAVA_HOME}/bin:${SPARK_HOME}/bin:${CONDA_DIR}/bin:${MESOSPHERE_PREFIX}/bin:${PATH}" \
    SHELL="/bin/bash" \
    SPARK_HOME=${SPARK_HOME:-"/opt/spark"}

RUN echo "deb ${REPO}/${DISTRO} ${CODENAME} main" \
         >> /etc/apt/sources.list \
    echo "deb ${REPO}/${DISTRO}-security ${CODENAME}/updates main" \
         >> /etc/apt/sources.list \
    && apt-get update -yq --fix-missing \
    && apt-get install -yq --no-install-recommends locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && apt-get install -yq --no-install-recommends apt-utils \
    && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
       bash-completion \
       bzip2 \
       ca-certificates \
       curl \
       dirmngr \
       git \
       gnupg \
       jq \
       openssh-client \
       procps \
       rsync \
       sudo \
       unzip \
       vim \
       wget \
    && apt-get clean \
    && rm -rf /var/apt/lists/*

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Apache Spark" \
      org.label-schema.description="Apache Spark is a fast and general engine for large-scale data processing" \
      org.label-schema.url="http://spark.apache.org" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vishnu2kmohan/spark" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="2.2.1-1.10.5"

COPY spark-root-conda-env.yml "${CONDA_DIR}/"

RUN cd /tmp \
    && mkdir -p "${CONDA_DIR}" "${JAVA_HOME}" "${SPARK_HOME}" \
    && mkdir -p "${MESOSPHERE_PREFIX}" "${MESOSPHERE_PREFIX}/bin" \
    && curl --retry 3 -fsSL -O "${LIBMESOS_BUNDLE_URL}/libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" \
    && echo "${LIBMESOS_BUNDLE_SHA256}" "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" -C "${MESOSPHERE_PREFIX}" \
    && rm "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" \
    && echo "${MESOSPHERE_PREFIX}/libmesos-bundle/lib" >> /etc/ld.so.conf.d/libmesos.conf \
    && cd "${MESOSPHERE_PREFIX}/libmesos-bundle/lib" \
    && curl --retry 3 -fsSL -O "${MESOS_MAVEN_URL}/${MESOS_VERSION}/mesos-${MESOS_VERSION}.jar" \
    && echo "${MESOS_JAR_SHA1} mesos-${MESOS_VERSION}.jar" | sha1sum -c - \
    && curl --retry 3 -fsSL -O "${MESOS_MAVEN_URL}/${MESOS_VERSION}/mesos-${MESOS_VERSION}-shaded-protobuf.jar" \
    && echo "${MESOS_PROTOBUF_JAR_SHA1} mesos-${MESOS_VERSION}-shaded-protobuf.jar" | sha1sum -c - \
    && cd /tmp \
    && curl --retry 3 -fsSL -O "${DCOS_COMMONS_URL}/artifacts/${DCOS_COMMONS_VERSION}/bootstrap.zip" \
    && unzip "bootstrap.zip" -d "${MESOSPHERE_PREFIX}/bin/" \
    && curl --retry 3 -fsSL -O "${JAVA_URL}/server-jre-${JAVA_VERSION}-linux-x64.tar.gz" \
    && tar xf "server-jre-${JAVA_VERSION}-linux-x64.tar.gz" -C "${JAVA_HOME}" --strip-components=1 \
    && curl --retry 3 -fsSL -O "${SPARK_DIST_URL}/assets/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz" \
    && tar xf "spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz" -C "${SPARK_HOME}" --strip-components=1 \
    && chmod -R ugo+rw "${SPARK_HOME}" \
    && curl --retry 3 -fsSL -O "$CONDA_URL/$CONDA_INSTALLER" \
    && echo "$CONDA_MD5  $CONDA_INSTALLER" | md5sum -c - \
    && bash "./$CONDA_INSTALLER" -u -b -p "$CONDA_DIR" \
    && $CONDA_DIR/bin/conda config --system --prepend channels conda-forge \
    && $CONDA_DIR/bin/conda config --system --set auto_update_conda false \
    && $CONDA_DIR/bin/conda config --system --set show_channel_urls true \
    && $CONDA_DIR/bin/conda update --json --all -yq \
    && $CONDA_DIR/bin/conda env update --json -q -f "${CONDA_DIR}/spark-root-conda-env.yml" \
    && $CONDA_DIR/bin/conda clean --json -tipsy \
    && rm -rf /tmp/* \
    && ldconfig

COPY conf/ "${SPARK_HOME}/conf/"
COPY krb5.conf.mustache /etc/
COPY mesos-dispatcher-start.sh "${MESOSPHERE_PREFIX}/bin"

WORKDIR "${SPARK_HOME}"