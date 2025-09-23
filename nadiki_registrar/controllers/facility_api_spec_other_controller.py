import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.facility_create import FacilityCreate  # noqa: E501
from nadiki_registrar.models.facility_response import FacilityResponse  # noqa: E501
from nadiki_registrar.models.facility_update import FacilityUpdate  # noqa: E501
from nadiki_registrar.models.list_facilities200_response import ListFacilities200Response  # noqa: E501
from nadiki_registrar import util

from nadiki_registrar.models.facility_time_series_config import FacilityTimeSeriesConfig  # noqa: E501
from nadiki_registrar.models.facility_create_cooling_fluids_inner import FacilityCreateCoolingFluidsInner  # noqa: E501
from nadiki_registrar.models.facility_impact_assessment import FacilityImpactAssessment  # noqa: E501
from nadiki_registrar.models.facility_time_series_data_point import FacilityTimeSeriesDataPoint  # noqa: E501
from nadiki_registrar.models.location import Location  # noqa: E501

import json
import urllib3
import urllib.parse
import country_converter as coco

from sqlalchemy import create_engine, MetaData, Table, select, delete, insert, update, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func

from nadiki_registrar.controllers.influxdb import influxdb_client
from influxdb_client import BucketRetentionRules
from influxdb_client import Permission
from influxdb_client import PermissionResource

from nadiki_registrar.controllers.config import *
from nadiki_registrar.controllers.database import *
from nadiki_registrar.controllers.identifiers import *

#
# Defaults
#
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

#
# urllib3
#
http = urllib3.PoolManager()

BASE_URL_FOR_NOMINATIM = "https://nominatim.openstreetmap.org/reverse?"

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

        try:
            country_code = __geo_location_to_country_code(facility_create.location.latitude, facility_create.location.longitude)
        except:
            return Error(code=400, message="Could not resolve geo location"), 400


        with engine.connect() as conn:
            try:
                conn.execute(insert(facilities).values({
                    "f_geo_lon": facility_create.location.latitude,
                    "f_geo_lat": facility_create.location.longitude,
                    "f_lifetime_facility": facility_create.lifetime_facility,
                    "f_installed_capacity": facility_create.installed_capacity,
                    "f_maintenance_hours_generator": facility_create.maintenance_hours_generator,
                    "f_grid_power_feeds": facility_create.grid_power_feeds,
                    "f_design_pue": facility_create.design_pue,
                    "f_tier_level": str(facility_create.tier_level), # MariaDB expects a string here
                    "f_white_space_floors": facility_create.white_space_floors,
                    "f_total_space": facility_create.total_space,
                    "f_white_space": facility_create.white_space,
                    "f_description": facility_create.description,
                    "f_country_code": country_code,
                    "f_influxdb_endpoint": INFLUXDB_EXTERNAL_ENDPOINT_URL,
                    "f_influxdb_org": INFLUXDB_ORG,
                    "f_influxdb_token": "TBD",
                    "f_created_at": func.now(),
                    "f_updated_at": func.now(),
                }))

                result = conn.execute(text("SELECT LAST_INSERT_ID() AS id FROM facilities"));
                id = next(result).id
                facility = FacilityId(country_code, id)

                # create a bucket in InfluxDB and create an auth token which is allowed to write to it
                bucket_api = influxdb_client.buckets_api()
                bucket = bucket_api.create_bucket(bucket_name=facility.toString(), org=INFLUXDB_ORG, retention_rules=BucketRetentionRules(type="expire", every_seconds=INFLUXDB_EXPIRY_SECONDS))

                org_api = influxdb_client.organizations_api()
                org_id = [x.id for x in org_api.find_organizations() if x.name == "Leitmotiv"].pop()

                auth_api = influxdb_client.authorizations_api()
                # why is it not possible to add a description to a token through the Python API? It is possible with the REST API...
                auth = auth_api.create_authorization(
                    org_id      = org_id,
                    # description = f"Ingestion token for bucket {facility.toString()}", ## why is this parameter not supported???
                    permissions = [
                        Permission(action="write", resource=PermissionResource(id=bucket.id, type="buckets")),
                        Permission(action="read", resource=PermissionResource(id=bucket.id, type="buckets"))
                    ]
                )
                conn.execute(update(facilities).values({"f_influxdb_token": auth.token}).where(facilities.c.f_id == id))

                # insert the weak entities (cooling fluids and time series configs)
                for x in facility_create.cooling_fluids:
                    conn.execute(insert(facilities_cooling_fluids).values({
                        "fcf_f_id": id,
                        "fcf_type": x.type,
                        "fcf_amount": x.amount,
                        "fcf_gwp_factor": x.gwp_factor
                    }))
                for x in REQUESTED_METRICS:
                    conn.execute(insert(facilities_timeseries_configs).values({
                        "ftc_f_id": id,
                        "ftc_measurement": "facility",
                        "ftc_field": x["name"],
                        "ftc_granularity_seconds": GRANULARITY_IN_SECONDS,
                        "ftc_tags": json.dumps(ADDITIONAL_LABELS | {
                            "country_code": country_code,
                            "facility_id": facility.toString()
                        })
                    }))
                for field_name, value in facility_create.impact_assessment.to_dict().items():
                    conn.execute(insert(facilities_impact_assessment).values({
                        "fia_f_id": id,
                        "fia_field_name": field_name,
                        "fia_value": value
                    }))
                conn.commit()
            except IntegrityError as e:
                return Error(code=400, message="A facility with this location already exists."), 400

        res, code = get_facility(facility.toString())
        return res, 201

def delete_facility(facility_id):  # noqa: E501
    """Delete facility

    Remove a facility from the registry # noqa: E501

    :param facility_id: Unique facility identifier
    :type facility_id: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """

    facility = FacilityId.fromString(facility_id)

    with engine.connect() as conn:
        result = conn.execute(delete(facilities).where(facilities.c.f_id == facility.number and facilities.c.f_country_code == facility.country_code))
        conn.commit()
        if result.rowcount == 1:
            return "Facility deleted", 204
        else:
            return Error(code=404, message="Facility not found"), 404


def get_facility(facility_id):  # noqa: E501
    """Get facility details

    Retrieve detailed information about a specific facility # noqa: E501

    :param facility_id: Unique facility identifier
    :type facility_id: str

    :rtype: Union[FacilityResponse, Tuple[FacilityResponse, int], Tuple[FacilityResponse, int, Dict[str, str]]
    """
    
    facility = FacilityId.fromString(facility_id)

    with engine.connect() as conn:
        facilities_result = conn.execute(select(facilities).where(facilities.c.f_id == facility.number and facilities.c.f_country_code == facility.country_code))
        facilities_cooling_fluids_result = conn.execute(select(facilities_cooling_fluids).where(facilities_cooling_fluids.c.fcf_f_id == facility.number))
        facilities_timeseries_configs_result = conn.execute(select(facilities_timeseries_configs).where(facilities_timeseries_configs.c.ftc_f_id == facility.number))
        facilities_impact_assessment_result = conn.execute(select(facilities_impact_assessment).where(facilities_impact_assessment.c.fia_f_id == facility.number))
#        for row in facilities_cooling_fluids:

        if facilities_result.rowcount == 0:
            return Error(code=404, message="Facility Id not found"), 404
        else:
            return _create_facility_response(next(facilities_result), facilities_cooling_fluids_result, facilities_timeseries_configs_result, facilities_impact_assessment_result), 200

    return "Nothing to see here", 404

def _create_facility_response(row, facilities_cooling_fluids_result, facilities_timeseries_configs_result, facilities_impact_assessment_result):
    facility = FacilityId(row.f_country_code, row.f_id)
    impact_assessment_dict = {x.fia_field_name: x.fia_value for x in facilities_impact_assessment_result}
    resp = FacilityResponse(
        id                              = facility.toString(),
        country_code                    = row.f_country_code,
        location                        = Location(latitude=row.f_geo_lat, longitude=row.f_geo_lon),
        lifetime_facility               = row.f_lifetime_facility,
        installed_capacity              = row.f_installed_capacity,
        impact_assessment               = FacilityImpactAssessment(**impact_assessment_dict),
        maintenance_hours_generator     = row.f_maintenance_hours_generator,
        grid_power_feeds                = row.f_grid_power_feeds,
        design_pue                      = row.f_design_pue,
        tier_level                      = row.f_tier_level,
        white_space_floors              = row.f_white_space_floors,
        total_space                     = row.f_total_space,
        white_space                     = row.f_white_space,
        description                     = row.f_description,
        time_series_config              = FacilityTimeSeriesConfig(endpoint=row.f_influxdb_endpoint, org=row.f_influxdb_org, bucket=facility.toString(), token=row.f_influxdb_token, data_points=[
            FacilityTimeSeriesDataPoint(measurement=x.ftc_measurement, field=x.ftc_field, granularity_seconds=x.ftc_granularity_seconds, tags=json.loads(x.ftc_tags)) for x in facilities_timeseries_configs_result
        ]),
        cooling_fluids                  = [
            FacilityCreateCoolingFluidsInner(type=x.fcf_type, amount=x.fcf_amount, gwp_factor=x.fcf_gwp_factor) for x in facilities_cooling_fluids_result
        ],
        created_at                      = row.f_created_at,
        updated_at                      = row.f_updated_at
    )
    return resp


def list_facilities(limit=None, offset=None):  # noqa: E501
    """List all facilities

    Retrieve a list of all registered facilities # noqa: E501

    :param limit: Maximum number of facilities to return
    :type limit: int
    :param offset: Number of facilities to skip
    :type offset: int

    :rtype: Union[ListFacilities200Response, Tuple[ListFacilities200Response, int], Tuple[ListFacilities200Response, int, Dict[str, str]]
    """

    with engine.connect() as conn:
        facilities_result = conn.execute(select(facilities).limit(limit).offset(offset))

#        for row in facilities_cooling_fluids:

        results = []
        for row in facilities_result:
            facilities_cooling_fluids_result = conn.execute(select(facilities_cooling_fluids).where(facilities_cooling_fluids.c.fcf_f_id == row.f_id))
            facilities_timeseries_configs_result = conn.execute(select(facilities_timeseries_configs).where(facilities_timeseries_configs.c.ftc_f_id == row.f_id))
            facilities_impact_assessment_result = conn.execute(select(facilities_impact_assessment).where(facilities_impact_assessment.c.fia_f_id == row.f_id))
            results.append(_create_facility_response(row, facilities_cooling_fluids_result, facilities_timeseries_configs_result, facilities_impact_assessment_result))

        resp = ListFacilities200Response(items=results, total=facilities_result.rowcount)
        return resp, 200


def update_facility(facility_id, facility_update=None):  # noqa: E501
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

        try:
            country_code = __geo_location_to_country_code(facility_update.location.latitude, facility_update.location.longitude)
        except:
            return Error(code=400, message="Could not resolve geo location"), 400


        facility = FacilityId.fromString(facility_id)
        with engine.connect() as conn:
            try:
                result = conn.execute(update(facilities).where(facilities.c.f_id == facility.number).values({
                    "f_geo_lon": facility_update.location.latitude,
                    "f_geo_lat": facility_update.location.longitude,
                    "f_lifetime_facility": facility_update.lifetime_facility,
                    "f_installed_capacity": facility_update.installed_capacity,
                    "f_maintenance_hours_generator": facility_update.maintenance_hours_generator,
                    "f_grid_power_feeds": facility_update.grid_power_feeds,
                    "f_design_pue": facility_update.design_pue,
                    "f_tier_level": str(facility_update.tier_level), # MariaDB expects a string here
                    "f_white_space_floors": facility_update.white_space_floors,
                    "f_total_space": facility_update.total_space,
                    "f_white_space": facility_update.white_space,
                    "f_description": facility_update.description,
                    "f_country_code": country_code,
                    "f_updated_at": func.now(),
                }))

                if result.rowcount != 1:
                    return Error(code=404, message="Facility not found"), 404

                conn.execute(delete(facilities_cooling_fluids).where(facilities_cooling_fluids.c.fcf_f_id == facility.number))

                for x in facility_update.cooling_fluids:
                    conn.execute(insert(facilities_cooling_fluids).values({
                        "fcf_f_id": facility.number,
                        "fcf_type": x.type,
                        "fcf_amount": x.amount,
                        "fcf_gwp_factor": x.gwp_factor
                    }))

                for field_name, value in facility.impact_assessment.items():
                    conn.execute(delete(facilities_impact_assessment).where(facilities_impact_assessment.c.fia_f_id == facility.number and facilities_impact_assessment.c.field_name == field_name))
                    conn.execute(insert(facilities_impact_assessment).values({
                        "fia_f_id": id,
                        "fia_field_name": field_name,
                        "fia_value": value
                    }))
                conn.commit()
            except IntegrityError as e:
                return Error(code=400, message="A facility with this location already exists."), 400

        return get_facility(facility_id)


def __geo_location_to_country_code(lat, lon):
    # resolve location to three letter countrycode
    # (TODO: exceptions here are likely for various reasons, maybe we should give the caller a hint on whether it was his fault or not)
    response = http.request("GET", BASE_URL_FOR_NOMINATIM+urllib.parse.urlencode({
        "lat": lat,
        "lon": lon,
        "format": "json"
    }), headers={"User-agent": "Nadiki Registrar https://github.com/SDIAlliance/nadiki-registrar"})
    return coco.convert(names=json.loads(response.data)["address"]["country_code"], to="ISO3")
