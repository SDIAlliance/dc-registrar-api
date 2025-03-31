import influxdb_client
from nadiki_registrar.controllers.config import *

influxdb_client = influxdb_client.InfluxDBClient(
    url=INFLUXDB_ENDPOINT_URL,
    token=INFLUXDB_ADMIN_TOKEN,
    org=INFLUXDB_ORG,
    verify_ssl=False # required to use the service discovery to connect internally
)