#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eo pipefail

REQUIREMENTS_LOCAL="/app/docker/requirements-local.txt"
# If Cypress run – overwrite the password for admin and export env variables
if [ "$CYPRESS_CONFIG" == "true" ]; then
    export SUPERSET_CONFIG=tests.integration_tests.superset_test_config
    export SUPERSET_TESTENV=true
    export SUPERSET__SQLALCHEMY_DATABASE_URI=postgresql+psycopg2://superset:superset@db:5432/superset
fi
#
# Make sure we have dev requirements installed
#
if [ -f "${REQUIREMENTS_LOCAL}" ]; then
  echo "Installing local overrides at ${REQUIREMENTS_LOCAL}"
  pip install --no-cache-dir -r "${REQUIREMENTS_LOCAL}"
else
  echo "Skipping local overrides"
fi

case "${1}" in
  worker)
    echo "Starting Celery worker 1..."
    # setting up only 2 workers by default to contain memory usage in dev environments
    # celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-2}
    #celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-8} --max-tasks-per-child=10000 --task-time-limit=3600 --prefetch-multiplier=1
    #celery --app=superset.tasks.celery_app:app worker --pool=prefork -O fair --concurrency=${CELERYD_CONCURRENCY:-4} --prefetch-multiplier=1
    #celery --app=superset.tasks.celery_app:app worker -l INFO -P gevent --concurrency=16
    celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=12 --max-memory-per-child=2048000  # 2GB per child process

    ;;
  worker1)
    echo "Starting Celery worker 1..."
    # setting up only 2 workers by default to contain memory usage in dev environments
    # celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-2}
    #celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-8} --max-tasks-per-child=10000 --task-time-limit=3600 --prefetch-multiplier=1
    #celery --app=superset.tasks.celery_app:app worker -n worker1@%h --pool=prefork -O fair --concurrency=${CELERYD_CONCURRENCY:-4} --prefetch-multiplier=1
    celery --app=superset.tasks.celery_app:app worker -n worker1@%h -O fair -l INFO --concurrency=12 --max-memory-per-child=2048000  # 2GB per child process
    #celery --app=superset.tasks.celery_app:app worker -l INFO -P gevent --concurrency=16

    ;;
  worker2)
    echo "Starting Celery worker 2..."
    # setting up only 2 workers by default to contain memory usage in dev environments
    # celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-2}
    #celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-8} --max-tasks-per-child=10000 --task-time-limit=3600 --prefetch-multiplier=1
    #celery --app=superset.tasks.celery_app:app worker -n worker2@%h --pool=prefork -O fair --concurrency=${CELERYD_CONCURRENCY:-4} --prefetch-multiplier=1    #celery --app=superset.tasks.celery_app:app worker -l INFO -P gevent --concurrency=16
    celery --app=superset.tasks.celery_app:app worker -n worker2@%h  -O fair -l INFO --concurrency=12 --max-memory-per-child=2048000  # 2GB per child process

    ;;
  worker3)
    echo "Starting Celery worker 3..."
    # setting up only 2 workers by default to contain memory usage in dev environments
    # celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-2}
    #celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --concurrency=${CELERYD_CONCURRENCY:-8} --max-tasks-per-child=10000 --task-time-limit=3600 --prefetch-multiplier=1
    #celery --app=superset.tasks.celery_app:app worker -n worker3@%h --pool=prefork -O fair --concurrency=${CELERYD_CONCURRENCY:-4} --prefetch-multiplier=1    #celery --app=superset.tasks.celery_app:app worker -l INFO -P gevent --concurrency=16
    celery --app=superset.tasks.celery_app:app worker -n worker3@%h -O fair -l INFO --concurrency=12 --max-memory-per-child=2048000  # 2GB per child process

    ;;
  beat)
    echo "Starting Celery beat..."
    rm -f /tmp/celerybeat.pid
    celery --app=superset.tasks.celery_app:app beat --pidfile /tmp/celerybeat.pid -l INFO -s "${SUPERSET_HOME}"/celerybeat-schedule
    ;;
  flower)
    echo "Starting Celery Flower..."
    echo "CELERY_BROKER_URL: ${CELERY_BROKER_URL}"
    echo "FLOWER_BASIC_AUTH: ${FLOWER_BASIC_AUTH}"
    celery --app=superset.tasks.celery_app:app --broker="${CELERY_BROKER_URL}" flower --basic_auth="${FLOWER_BASIC_AUTH}"

    ;;
  app)
    echo "Starting web app (using development server)..."
    flask run -p 8088 --with-threads --reload --debugger --host=0.0.0.0
    ;;
  app-gunicorn)
    echo "Starting web app..."
    /usr/bin/run-server.sh
    ;;
  *)
    echo "Unknown Operation!!!"
    ;;
esac
