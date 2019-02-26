#!/bin/bash
cd /app/lightsheet-pipeline
source env/bin/activate
./env/bin/uwsgi --ini /app/ipp.ini

