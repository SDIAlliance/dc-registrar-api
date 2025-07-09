#!/bin/bash

#tmpdir=$(mktemp -d /var/tmp/XXXXXX)
#for s in data-center-facility/facility-api.spec.yaml rack/rack-api.spec.yaml server/server-api.spec.yaml ; do
#	curl -O --output-dir $tmpdir https://raw.githubusercontent.com/SDIAlliance/nadiki-api/refs/heads/main/$s
#done

# specdir=~/work/leitmotiv/nadiki-api
specdir=~/code/nadiki/nadiki-api

docker run -v $specdir:/local -w /local redocly/cli join data-center-facility/facility-api.spec.yaml rack/rack-api.spec.yaml server/server-api.spec.yaml -o nadiki-api.yaml

docker run --user $(id -u) --rm -v "${PWD}:/local/out" -v "${specdir}:/local/in" openapitools/openapi-generator-cli:v6.6.0 generate \
    -i /local/in/nadiki-api.yaml \
    -g python-flask \
    -o /local/out \
    --package-name nadiki_registrar
#    --skip-validate-spec \

#rm -r $tmpdir
