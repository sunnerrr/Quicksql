#!/bin/bash
USAGE="-e Usage: quicksql-server.sh {start|stop|restart|status}"
export QSQL_HOME="$(cd "`dirname "$0"`"/..; pwd)"

function start() {
        JAVA_MAIN_CLASS="com.qihoo.qsql.server.JdbcServer"
        QSQL_SERVER_JAR="${QSQL_HOME}/lib/qsql-server-0.6.jar"


        PIDS=`ps -f | grep java | grep "$QSQL_HOME" |awk '{print $2}'`
        if [ -n "$PIDS" ]; then
            echo "ERROR: The $QSQL_HOME quicksql-server already started!"
            echo "PID: $PIDS"
            exit 1
        fi

        . "${QSQL_HOME}/bin/load-qsql-env"
        . "${QSQL_HOME}/bin/qsql-env"

        QSQL_JARS1=${QSQL_HOME}/lib/sqlite-jdbc-3.20.0.jar,${QSQL_HOME}/lib/qsql-meta-0.6.jar,${QSQL_HOME}/lib/jackson-dataformat-cbor-2.8.10.jar,${QSQL_HOME}/lib/jackson-dataformat-smile-2.8.10.jar,${QSQL_HOME}/lib/qsql-client-0.6.jar,${QSQL_HOME}/lib/jetty-http-9.2.19.v20160908.jar,${QSQL_HOME}/lib/jetty-io-9.2.19.v20160908.jar,${QSQL_HOME}/lib/jetty-security-9.2.19.v20160908.jar,${QSQL_HOME}/lib/jetty-server-9.2.19.v20160908.jar,${QSQL_HOME}/lib/jetty-util-9.2.19.v20160908.jar,${QSQL_HOME}/lib/commons-cli-1.3.1.jar,${QSQL_HOME}/lib/avatica-core-1.12.0.jar,${QSQL_HOME}/lib/avatica-server-1.12.0.jar,${QSQL_HOME}/lib/avatica-metrics-1.12.0.jar,${QSQL_HOME}/lib/protobuf-java-3.3.0.jar,${QSQL_HOME}/lib/jackson-core-2.6.5.jar,${QSQL_HOME}/lib/jackson-annotations-2.6.5.jar,${QSQL_HOME}/lib/jackson-databind-2.6.5.jar,${QSQL_HOME}/lib/httpclient-4.5.6.jar,${QSQL_HOME}/lib/httpcore-4.4.10.jar,${QSQL_HOME}/lib/esri-geometry-api-2.2.0.jar,${QSQL_HOME}/lib/guava-19.0.jar,${QSQL_HOME}/lib/calcite-linq4j-1.17.0.jar,${QSQL_HOME}/lib/derby-10.10.2.0.jar,${QSQL_HOME}/lib/jackson-dataformat-yaml-2.6.5.jar,${QSQL_HOME}/lib/imc-0.2.jar,${QSQL_HOME}/lib/qsql-core-0.6.jar,${QSQL_HOME}/lib/qsql-calcite-analysis-0.6.jar,${QSQL_HOME}/lib/qsql-calcite-elasticsearch-0.6.jar,${QSQL_HOME}/lib/elasticsearch-rest-client-6.2.4.jar,${QSQL_HOME}/lib/httpasyncclient-4.1.2.jar,${QSQL_HOME}/lib/httpclient-4.5.6.jar,${QSQL_HOME}/lib/httpcore-4.4.10.jar,${QSQL_HOME}/lib/httpcore-nio-4.4.5.jar,${QSQL_HOME}/lib/mysql-connector-java-5.1.20.jar,${QSQL_HOME}/lib/elasticsearch-spark-20_2.11-6.2.4.jar
        QSQL_LAUNCH_CLASSPATH="${QSQL_JARS1}"

        LOGS_DIR=""
        if [ -n "$LOGS_FILE" ]; then
            LOGS_DIR=`dirname $LOGS_FILE`
        else
            LOGS_DIR=$QSQL_HOME/logs
        fi
        if [ ! -d $LOGS_DIR ]; then
            mkdir $LOGS_DIR
        fi
        STDOUT_FILE=$LOGS_DIR/stdout.log

        echo ${STDOUT_FILE}

        echo " ${SPARK_HOME}/bin/spark-submit --jars ${QSQL_LAUNCH_CLASSPATH} --master local[1] --executor-memory 1G --driver-memory 3G --num-executors 20 --conf spark.driver.userClassPathFirst=true --class  ${JAVA_MAIN_CLASS} ${QSQL_SERVER_JAR}"
        nohup ${SPARK_HOME}/bin/spark-submit --jars "${QSQL_LAUNCH_CLASSPATH}" --master local[1] --executor-memory 1G --driver-memory 3G --num-executors 20 --conf spark.driver.userClassPathFirst=true --class  ${JAVA_MAIN_CLASS} ${QSQL_SERVER_JAR}  > $STDOUT_FILE 2>&1 &

        COUNT=0
        while [ $COUNT -lt 1 ]; do
            echo -e ".\c"
            sleep 1
            COUNT=`ps -f | grep java | grep "$QSQL_HOME" | awk '{print $2}' | wc -l`
            if [ $COUNT -gt 0 ]; then
                break
            fi
        done
        echo "OK!"
        PIDS=`ps -f | grep java | grep "$QSQL_HOME" | awk '{print $2}'`
        echo "PID: $PIDS"
        echo "STDOUT: $STDOUT_FILE"
}

function stop() {
        PIDS=`ps -ef | grep java | grep "$QSQL_HOME" |awk '{print $2}'`
        if [ -z "$PIDS" ]; then
            echo "ERROR: The $QSQL_HOME quicksql-server does not started!"
            exit 1
        fi
        echo -e "Stopping the $QSQL_HOME quicksql-server ...\c"
              for PID in $PIDS ; do
                  kill $PID > /dev/null 2>&1
              done

              COUNT=0
              while [ $COUNT -lt 1 ]; do
                  echo -e ".\c"
                  sleep 1
                  COUNT=1
                  for PID in $PIDS ; do
                      PID_EXIST=`ps -f -p $PID | grep java`
                      if [ -n "$PID_EXIST" ]; then
                        COUNT=0
                          break
                      fi
                  done
              done

              echo "OK!"
              echo "PID: $PIDS"
}

function find_app_process() {
        PIDS=`ps -ef | grep java | grep "$QSQL_HOME" |awk '{print $2}'`
        if [ -z "$PIDS" ]; then
            echo "The $QSQL_HOME quicksql-server does not running!"
            exit 1
        else
                echo "The $QSQL_HOME quicksql-server is running!"
                exit 1
        fi
}

case "${1}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        find_app_process
        ;;
    *)
    echo ${USAGE}
esac

