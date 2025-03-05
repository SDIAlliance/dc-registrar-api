import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.facility_create import FacilityCreate  # noqa: E501
from nadiki_registrar.models.facility_metrics_query import FacilityMetricsQuery  # noqa: E501
from nadiki_registrar.models.facility_metrics_query_response import FacilityMetricsQueryResponse  # noqa: E501
from nadiki_registrar.models.facility_response import FacilityResponse  # noqa: E501
from nadiki_registrar.models.facility_update import FacilityUpdate  # noqa: E501
from nadiki_registrar.models.list_facilities200_response import ListFacilities200Response  # noqa: E501
from nadiki_registrar import util

from nadiki_registrar.models.facility_time_series_config import FacilityTimeSeriesConfig  # noqa: E501

import json
from uuid import uuid4
from sqlalchemy import create_engine, text, MetaData, Table, select, delete, insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func
#
# Initialize SQLAlchemy
#
engine = create_engine("mysql+pymysql://root:toogood4u@localhost/nadiki_registrar?charset=utf8mb4")
meta = MetaData()
meta.reflect(engine)
facilities = Table("facilities", meta, autoload_with=engine)
facilities_cooling_fluids = Table("facilities_cooling_fluids", meta, autoload_with=engine)
facilities_timeseries_configs = Table("facilities_timeseries_configs", meta, autoload_with=engine)

#
# Defaults
#

PROMETHEUS_ENDPOINT_URL = "https://pro.me/theus"
REQUESTED_METRICS = [
    { "name": "heatpump_power_consumption_joules",      "unit": "Energy" },
    { "name": "office_energy_use_joules",               "unit": "Energy" },
    { "name": "dc_water_usage_cubic_meters",            "unit": "Length" },
    { "name": "office_water_usage_cubic_meters",        "unit": "Length" },
    { "name": "total_generator_energy_joules",          "unit": "Energy" },
    { "name": "generator_load_factor_ratio",            "unit": "Percent" },
    { "name": "grid_transformers_energy_joules",        "unit": "Energy" },
    { "name": "onsite_renewable_energy_joules",         "unit": "Energy" },
    { "name": "it_power_usage_level1_joules",           "unit": "Energy" },
    { "name": "it_power_usage_level2_joules",           "unit": "Energy" },
    { "name": "renewable_energy_certificates_joules",   "unit": "Energy" },
    { "name": "grid_emission_factor_grams",             "unit": "Mass" },
    { "name": "backup_emission_factor_grams",           "unit": "Mass" },
    { "name": "electricity_source",                     "unit": "Value" },
    { "name": "pue_1_ratio",                            "unit": "Percent" },
    { "name": "pue_2_ratio",                            "unit": "Percent" }
]
GRANULARITY_IN_SECONDS = 30
ADDITIONAL_LABELS = {} # this will not work right now because the OpenAPI spec only allows two fixed labels

#def create_facility(body, facility_create):  # noqa: E501
def create_facility(facility_create=None):  # noqa: E501
    """Register a new facility

    Create a new facility entry in the registry # noqa: E501

    :param facility_create: 
    :type facility_create: dict | bytes

    :rtype: Union[FacilityResponse, Tuple[FacilityResponse, int], Tuple[FacilityResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        facility_create = FacilityCreate.from_dict(connexion.request.get_json())  # noqa: E501
        resp = FacilityResponse()
        resp.id = uuid4()
        resp.country_code = "DEU" # FIXME: get this from the geo location
        # FIXME: this does not work, because all other attributes will be gone afterwards:
        #resp.__dict__.update(facility_create.__dict__)
        resp.time_series_config = FacilityTimeSeriesConfig.from_dict({
            "endpoint": PROMETHEUS_ENDPOINT_URL,
            "dataPoints": [
                {
                    "name": x["name"],
                    "unit": x["unit"],
                    "granularitySeconds": GRANULARITY_IN_SECONDS,
                    "labels": ADDITIONAL_LABELS | {
                        "facility_id": resp.id,
                        "country_code": resp.country_code
                    }
                }
            for x in REQUESTED_METRICS]
        })
        with engine.connect() as conn:
            try:
                conn.execute(insert(facilities).values({
                    "f_id": resp.id,
                    "f_geo_lon": facility_create.location.latitude,
                    "f_geo_lat": facility_create.location.longitude,
                    "f_embedded_ghg_emissions_facility": facility_create.embedded_ghg_emissions_facility,
                    "f_lifetime_facility": facility_create.lifetime_facility,
                    "f_embedded_ghg_emissions_assets": facility_create.embedded_ghg_emissions_assets,
                    "f_lifetime_assets": facility_create.lifetime_assets,
                    "f_maintenance_hours_generator": facility_create.maintenance_hours_generator,
                    "f_installed_capacity": facility_create.installed_capacity,
                    "f_grid_power_feeds": facility_create.grid_power_feeds,
                    "f_design_pue": facility_create.design_pue,
                    "f_tier_level": str(facility_create.tier_level), # MariaDB expects a string here
                    "f_white_space_floors": facility_create.white_space_floors,
                    "f_total_space": facility_create.total_space,
                    "f_white_space": facility_create.white_space,
                    "f_country_code": resp.country_code,
                    "f_prometheus_endpoint": PROMETHEUS_ENDPOINT_URL,
                    "f_created_at": func.now(),
                    "f_updated_at": func.now(),
                }))
                for x in facility_create.cooling_fluids:
                    conn.execute(insert(facilities_cooling_fluids).values({
                        "fcf_f_id": resp.id,
                        "fcf_type": x.type,
                        "fcf_amount": x.amount,
                        "fcf_gwp_factor": x.gwp_factor
                    }))
                for x in REQUESTED_METRICS:
                    conn.execute(insert(facilities_timeseries_configs).values({
                        "ftc_f_id": resp.id,
                        "ftc_name": x["name"],
                        "ftc_unit": x["unit"],
                        "ftc_granularity_seconds": GRANULARITY_IN_SECONDS,
                        "ftc_labels": json.dumps(ADDITIONAL_LABELS | {
                            "country_code": resp.country_code,
                            "facility_id": str(resp.id)
                        })
                    }))
                conn.commit()
            except IntegrityError as e:
                return Error("A facility with this location already exists."), 400

        return resp, 201

    return 'do some magic!'


def delete_facility(facility_id):  # noqa: E501
    """Delete facility

    Remove a facility from the registry # noqa: E501

    :param facility_id: Unique facility identifier
    :type facility_id: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    return 'do some magic!'


def get_facility(facility_id):  # noqa: E501
    """Get facility details

    Retrieve detailed information about a specific facility # noqa: E501

    :param facility_id: Unique facility identifier
    :type facility_id: str

    :rtype: Union[FacilityResponse, Tuple[FacilityResponse, int], Tuple[FacilityResponse, int, Dict[str, str]]
    """
    return 'do some magic!'


def list_facilities(limit=None, offset=None):  # noqa: E501
    """List all facilities

    Retrieve a list of all registered facilities # noqa: E501

    :param limit: Maximum number of facilities to return
    :type limit: int
    :param offset: Number of facilities to skip
    :type offset: int

    :rtype: Union[ListFacilities200Response, Tuple[ListFacilities200Response, int], Tuple[ListFacilities200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def query_facility_metrics(facility_id, facility_metrics_query):  # noqa: E501
    """Query facility metrics

    Retrieve aggregated time series metrics for a facility over a specified time period # noqa: E501

    :param facility_id: Unique facility identifier
    :type facility_id: str
    :param facility_metrics_query: 
    :type facility_metrics_query: dict | bytes

    :rtype: Union[FacilityMetricsQueryResponse, Tuple[FacilityMetricsQueryResponse, int], Tuple[FacilityMetricsQueryResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        facility_metrics_query = FacilityMetricsQuery.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def update_facility(facility_id, facility_update):  # noqa: E501
    """Update facility

    Update all facility information # noqa: E501

    :param facility_id: Unique facility identifier
    :type facility_id: str
    :param facility_update: 
    :type facility_update: dict | bytes

    :rtype: Union[FacilityResponse, Tuple[FacilityResponse, int], Tuple[FacilityResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        facility_update = FacilityUpdate.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'
