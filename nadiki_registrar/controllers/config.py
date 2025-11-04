import os

INFLUXDB_ENDPOINT_URL = os.getenv('INFLUXDB_ENDPOINT_URL')
INFLUXDB_EXTERNAL_ENDPOINT_URL = os.getenv('INFLUXDB_EXTERNAL_ENDPOINT_URL')
INFLUXDB_ORG = os.getenv('INFLUXDB_ORG')
INFLUXDB_ADMIN_TOKEN = os.getenv('INFLUXDB_ADMIN_TOKEN')
INFLUXDB_EXPIRY_SECONDS = 1209600 # 14d
GRANULARITY_IN_SECONDS = 30
ADDITIONAL_LABELS = {} # this will not work right now because the OpenAPI spec only allows two fixed labels
#DATABASE_URL="mysql+pymysql://root:toogood4u@localhost/nadiki_registrar?charset=utf8mb4"
DATABASE_URL=f"mysql+pymysql://{os.getenv('DATABASE_USER')}:{os.getenv('DATABASE_PASSWORD')}@{os.getenv('DATABASE_HOST')}/nadiki_registrar?charset=utf8mb4"

# These defaults are valid for a 1MW datacenter and need to be scaled accordingly
FACILITY_IMPACT_ASSESSMENT_DEFAULTS = {
# Climate change impact in kg CO2 eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "climate_change": 608571.43,
# Ozone depletion impact in kg CFC-11 eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "ozone_depletion": 4.94,
# Human toxicity impact in kg 1,4-DB eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "human_toxicity": 2622857.14,
# Photochemical oxidant formation impact in kg NMVOC. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "photochemical_oxidant_formation": 2194.29,
# Particulate matter formation impact in kg PM10 eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "particulate_matter_formation": 2302.86,
# Ionizing radiation impact in kg U235 eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "ionizing_radiation": 88000.00,
# Terrestrial acidification impact in kg SO2 eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "terrestrial_acidification": 4142.86,
# Freshwater eutrophication impact in kg P eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "freshwater_eutrophication": 1257.14,
# Marine eutrophication impact in kg N eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "marine_eutrophication": 720.00,
# Terrestrial ecotoxicity impact in kg 1,4-DB eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "terrestrial_ecotoxicity": 971.43,
# Freshwater ecotoxicity impact in kg 1,4-DB eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "freshwater_ecotoxicity": 29142.86,
# Marine ecotoxicity impact in kg 1,4-DB eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "marine_ecotoxicity": 33714.29,
# Agricultural land occupation impact in m2a. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "agricultural_land_occupation": 70571.43,
# Urban land occupation impact in m2a. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "urban_land_occupation": 9000.00,
# Natural land transformation impact in m2. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "natural_land_transformation": 594.29,
# Water depletion impact in m3. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "water_depletion": 4485.71,
# Metal depletion impact in kg Fe eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "metal_depletion": 734285.71,
# Fossil depletion impact in kg oil eq. Default derived for a 1 MW data center and scaled according to installedCapacity.
        "fossil_depletion": 1042857.1 
}