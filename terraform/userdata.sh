#!/bin/bash

dnf install -y docker
systemctl enable docker
systemctl start docker

influxdb_token=$(aws secretsmanager get-secret-value --secret-id ${influxdb_token_secret_arn} | jq -r .SecretString)

aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com

docker run \
    -e TAG_SERVER_ID_MAPPING_SECRETS_ARN=${server_id_mapping_secret_arn} \
    -e OUTPUT_INFLUXDB_URL=${influxdb_url} \
    -e OUTPUT_INFLUXDB_TOKEN=$influxdb_token \
    -e OUTPUT_INFLUXDB_ORGANIZATION=Leitmotiv \
    -e VM_TIMEZONE=UTC \
    -e TAG_FACILITY_ID=XION \
    -e TAG_COUNTRY_CODE=DEU \
    -e TAG_RACK_ID=rack-1 \
    -e PROTON_HOST=${timeplus_proton_host} \
    -e AWS_REGION=${aws_region} \
    -e TZ=utc \
    -d ${repo_url}

