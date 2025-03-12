import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_racks200_response import ListRacks200Response  # noqa: E501
from nadiki_registrar.models.rack_create import RackCreate  # noqa: E501
from nadiki_registrar.models.rack_response import RackResponse  # noqa: E501
from nadiki_registrar.models.rack_update import RackUpdate  # noqa: E501
from nadiki_registrar import util

from nadiki_registrar.models.rack_time_series_config import RackTimeSeriesConfig  # noqa: E501
from nadiki_registrar.models.rack_time_series_data_point import RackTimeSeriesDataPoint  # noqa: E501

import json

from uuid import uuid4
from sqlalchemy import create_engine, MetaData, Table, select, delete, insert, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func

from nadiki_registrar.controllers.config import *
from nadiki_registrar.controllers.database import *
from nadiki_registrar.controllers.identifiers import *

def create_rack(rack_create=None):  # noqa: E501
    """Register a new rack

    Create a new rack entry in the registry # noqa: E501

    :param rack_create: 
    :type rack_create: dict | bytes

    :rtype: Union[RackResponse, Tuple[RackResponse, int], Tuple[RackResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        rack_create = RackCreate.from_dict(connexion.request.get_json())  # noqa: E501

        facility = FacilityId.fromString(rack_create.facility_id)

        with engine.connect() as conn:
            try:
                conn.execute(insert(racks).values({
                    "r_f_id":                               facility.number,
                    "r_total_available_power":              rack_create.total_available_power,
                    "r_total_available_cooling_capacity":   rack_create.total_available_cooling_capacity,
                    "r_number_of_pdus":                     rack_create.number_of_pdus,
                    "r_power_redundancy":                   rack_create.power_redundancy,
                    "r_product_passport":                   json.dumps(rack_create.product_passport),
                    "r_prometheus_endpoint":                PROMETHEUS_ENDPOINT_URL,
                    "r_created_at":                         func.now(),
                    "r_updated_at":                         func.now()
                }))
            except IntegrityError as e:
                return Error(message="Integrity error", details="Does the given facility ID exist?", code=400), 400

            result = conn.execute(text("SELECT LAST_INSERT_ID() AS id FROM racks"))
            id = next(result).id
            rack = RackId(rack_create.facility_id, id)

            for t in [{
                    "name": "inlet_temperature_celsius",
                    "unit": "Temperature"
                },
                {
                    "name": "outlet_temperature_celsius",
                    "unit": "Temperature"
                }
            ]+[{"name": f"pdu_{n}_energy_consumption_joules", "unit": "Energy"} for n in range(1, rack_create.number_of_pdus+1)]:
                conn.execute(insert(racks_timeseries_configs).values(
                    {
                        "rtc_r_id": id,
                        "rtc_name": t["name"],
                        "rtc_unit": t["unit"],
                        "rtc_granularity_seconds": GRANULARITY_IN_SECONDS,
                        "rtc_labels": json.dumps({
                            "facility_id": rack_create.facility_id,
                            "rack_id": rack.toString(),
                            "country_code": rack.facility.country_code
                        })
                    }))
            conn.commit()

        return get_rack(rack.toString()), 201


def delete_rack(rack_id):  # noqa: E501
    """Delete rack

    Remove a rack from the registry # noqa: E501

    :param rack_id: Unique rack identifier (format RACK-[FACILITY_ID]-[RACK_ID])
    :type rack_id: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """

    rack = RackId.fromString(rack_id)
    with engine.connect() as conn:
        result = conn.execute(delete(racks).where(racks.c.r_id == rack.number and racks.c.r_f_id == rack.facility.number))
        conn.commit()
        if result.rowcount == 1:
            return "Rack deleted", 204
        else:
            return Error(code=404, message="Rack not found"), 404


def get_rack(rack_id):  # noqa: E501
    """Get rack details

    Retrieve detailed information about a specific rack # noqa: E501

    :param rack_id: Unique rack identifier (format RACK-[FACILITY_ID]-[RACK_ID])
    :type rack_id: str

    :rtype: Union[RackResponse, Tuple[RackResponse, int], Tuple[RackResponse, int, Dict[str, str]]
    """
    rack = RackId.fromString(rack_id)
    with engine.connect() as conn:
        result = conn.execute(select(racks.join(facilities, racks.c.r_f_id == facilities.c.f_id)).where(racks.c.r_id == rack.number and racks.c.r_facility_id == rack.facility.number))
        rack_timeseries_configs_result = conn.execute(select(racks_timeseries_configs).where(racks_timeseries_configs.c.rtc_r_id == rack.number))
        if result.rowcount == 0:
            return Error(code=404, message="Rack Id not found"), 404
        else:
            return _create_rack_response(next(result), rack_timeseries_configs_result)

def _create_rack_response(row, timeseries_configs_result):
    facility = FacilityId(row.f_country_code, row.f_id)
    rack = RackId(facility, row.r_id)
    resp = RackResponse(
        id                              = rack.toString(),
        facility_id                     = facility.toString(),
        total_available_power           = row.r_total_available_power,
        total_available_cooling_capacity= row.r_total_available_cooling_capacity,
        number_of_pdus                  = row.r_number_of_pdus,
        power_redundancy                = row.r_power_redundancy,
        product_passport                = row.r_product_passport,
        time_series_config              = RackTimeSeriesConfig(
            endpoint    = row.r_prometheus_endpoint,
            data_points = [RackTimeSeriesDataPoint(
                name                = x.rtc_name,
                unit                = x.rtc_unit,
                granularity_seconds = x.rtc_granularity_seconds,
                labels              = json.loads(x.rtc_labels)
            ) for x in timeseries_configs_result]
        ),
        created_at                      = row.r_created_at,
        updated_at                      = row.r_updated_at
    )
    return resp


def list_racks(limit=None, offset=None, facility_id=None):  # noqa: E501
    """List all racks

    Retrieve a list of all registered racks # noqa: E501

    :param limit: Maximum number of racks to return
    :type limit: int
    :param offset: Number of racks to skip
    :type offset: int
    :param facility_id: Filter racks by facility ID
    :type facility_id: str

    :rtype: Union[ListRacks200Response, Tuple[ListRacks200Response, int], Tuple[ListRacks200Response, int, Dict[str, str]]
    """

    with engine.connect() as conn:
        racks_result = conn.execute(select(racks.join(facilities, racks.c.r_f_id == facilities.c.f_id)).limit(limit).offset(offset))

        results = []
        for row in racks_result:
            rack_timeseries_configs_result = conn.execute(select(racks_timeseries_configs).where(racks_timeseries_configs.c.rtc_r_id == row.r_id))
            results.append(_create_rack_response(row, rack_timeseries_configs_result))

        resp = ListRacks200Response(items=results, total=racks_result.rowcount)
        return resp, 200


def update_rack(rack_id, rack_update):  # noqa: E501
    """Update rack

    Update all rack information # noqa: E501

    :param rack_id: Unique rack identifier (format RACK-[FACILITY_ID]-[RACK_ID])
    :type rack_id: str
    :param rack_update: 
    :type rack_update: dict | bytes

    :rtype: Union[RackResponse, Tuple[RackResponse, int], Tuple[RackResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        rack_update = RackUpdate.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'
