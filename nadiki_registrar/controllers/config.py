import os

PROMETHEUS_ENDPOINT_URL = "https://pro.me/theus"
GRANULARITY_IN_SECONDS = 30
ADDITIONAL_LABELS = {} # this will not work right now because the OpenAPI spec only allows two fixed labels
#DATABASE_URL="mysql+pymysql://root:toogood4u@localhost/nadiki_registrar?charset=utf8mb4"
DATABASE_URL=f"mysql+pymysql://{os.getenv('DATABASE_USER')}:{os.getenv('DATABASE_PASSWORD')}@{os.getenv('DATABASE_HOST')}/nadiki_registrar?charset=utf8mb4"
