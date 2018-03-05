#!/usr/bin/env bash
set -e
set -x

exec 2>&1

SPARK_DIST_PATH=${SPARK_HOME:-"/opt/spark"}

function export_daemon_opts() {
    export SPARK_DAEMON_JAVA_OPTS=${SPARK_DAEMON_JAVA_OPTS:-""}
    if [ "${DCOS_SERVICE_NAME}" != "spark" ]; then
        local ZK_SUFFIX=${DCOS_SERVICE_NAME////__}
        export SPARK_DAEMON_JAVA_OPTS="${SPARK_DAEMON_JAVA_OPTS} -Dspark.deploy.zookeeper.dir=/spark_mesos_dispatcher${ZK_SUFFIX}"
    fi

    if [ "$SPARK_DISPATCHER_MESOS_ROLE" != "" ]; then
        export SPARK_DAEMON_JAVA_OPTS="${SPARK_DAEMON_JAVA_OPTS} -Dspark.mesos.role=$SPARK_DISPATCHER_MESOS_ROLE"
    fi

    if [ "$SPARK_DISPATCHER_MESOS_PRINCIPAL" != "" ]; then
        export SPARK_DAEMON_JAVA_OPTS="${SPARK_DAEMON_JAVA_OPTS} -Dspark.mesos.principal=$SPARK_DISPATCHER_MESOS_PRINCIPAL"
    fi

    if [ "$SPARK_DISPATCHER_MESOS_SECRET" != "" ]; then
        export SPARK_DAEMON_JAVA_OPTS="${SPARK_DAEMON_JAVA_OPTS} -Dspark.mesos.secret=$SPARK_DISPATCHER_MESOS_SECRET"
    fi
}

function set_log_level() {
    sed "s,<LOG_LEVEL>,${SPARK_LOG_LEVEL}," \
        "${SPARK_DIST_PATH}/conf/log4j.properties.template" > "${SPARK_DIST_PATH}/conf/log4j.properties"
}

function add_if_non_empty() {
        if [ -n "$2" ]; then
                echo "$1=$2" >> "${SPARK_DIST_PATH}/conf/mesos-cluster-dispatcher.properties"
        fi
}

function configure_properties() {
    if [ "${SPARK_SSL_KEYSTOREBASE64}" != "" ]; then
        echo "${SPARK_SSL_KEYSTOREBASE64}" | base64 -d > /tmp/dispatcher-keystore.jks
        add_if_non_empty spark.ssl.keyStore /tmp/dispatcher-keystore.jks
    fi

    if [ "${SPARK_SSL_TRUSTSTOREBASE64}" != "" ]; then
        echo "${SPARK_SSL_TRUSTSTOREBASE64}" | base64 -d > /tmp/dispatcher-truststore.jks
        add_if_non_empty spark.ssl.trustStore /tmp/dispatcher-truststore.jks
    fi

    add_if_non_empty spark.mesos.dispatcher.historyServer.url "${SPARK_HISTORY_SERVER_URL}"
    add_if_non_empty spark.ssl.enabled "${SPARK_SSL_ENABLED}"
    add_if_non_empty spark.ssl.keyPassword "${SPARK_SSL_KEYPASSWORD}"
    add_if_non_empty spark.ssl.keyStorePassword "${SPARK_SSL_KEYSTOREPASSWORD}"
    add_if_non_empty spark.ssl.trustStorePassword "${SPARK_SSL_TRUSTSTOREPASSWORD}"
    add_if_non_empty spark.ssl.protocol "${SPARK_SSL_PROTOCOL}"
    add_if_non_empty spark.ssl.enabledAlgorithms "${SPARK_SSL_ENABLEDALGORITHMS}"
    echo "spark.mesos.proxy.baseURL=../../mesos" >> "${SPARK_DIST_PATH}/conf/mesos-cluster-dispatcher.properties"
}

export APPLICATION_WEB_PROXY_BASE="${DISPATCHER_UI_WEB_PROXY_BASE}"
set_log_level
export_daemon_opts
configure_properties
ZK=${ZK:-"zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181"}

exec "${SPARK_DIST_PATH}/bin/spark-class" \
    org.apache.spark.deploy.mesos.MesosClusterDispatcher \
    --port "${DISPATCHER_PORT}" \
    --webui-port "${DISPATCHER_UI_PORT}" \
    --master "mesos://zk://${ZK}/mesos" \
    --zk "${ZK}" \
    --host "${HOST}" \
    --name "${DCOS_SERVICE_NAME}" \
    --properties-file "${SPARK_DIST_PATH}/conf/mesos-cluster-dispatcher.properties"
