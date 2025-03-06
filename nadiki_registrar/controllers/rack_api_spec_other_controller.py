import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_racks200_response import ListRacks200Response  # noqa: E501
from nadiki_registrar.models.rack_create import RackCreate  # noqa: E501
from nadiki_registrar.models.rack_metrics_query import RackMetricsQuery  # noqa: E501
from nadiki_registrar.models.rack_metrics_query_response import RackMetricsQueryResponse  # noqa: E501
from nadiki_registrar.models.rack_response import RackResponse  # noqa: E501
from nadiki_registrar.models.rack_update import RackUpdate  # noqa: E501
from nadiki_registrar import util

from nadiki_registrar.models.rack_time_series_config import RackTimeSeriesConfig  # noqa: E501
from nadiki_registrar.models.rack_time_series_data_point import RackTimeSeriesDataPoint  # noqa: E501

import json

from uuid import uuid4
from sqlalchemy import create_engine, MetaData, Table, select, delete, insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func

from nadiki_registrar.controllers.config import *
from nadiki_registrar.controllers.database import *

def create_rack(rack_create=None):  # noqa: E501
    """Register a new rack

    Create a new rack entry in the registry # noqa: E501

    :param rack_create: 
    :type rack_create: dict | bytes

    :rtype: Union[RackResponse, Tuple[RackResponse, int], Tuple[RackResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        rack_create = RackCreate.from_dict(connexion.request.get_json())  # noqa: E501
        rack_id = uuid4()
        resp = RackResponse(
            id                              = rack_id,
            facility_id                     = rack_create.facility_id,
            total_available_power           = rack_create.total_available_power,
            total_available_cooling_capacity= rack_create.total_available_cooling_capacity,
            number_of_pdus                  = rack_create.number_of_pdus,
            power_redundancy                = rack_create.power_redundancy,
            product_passport                = rack_create.product_passport,
            time_series_config              = RackTimeSeriesConfig(
                endpoint=PROMETHEUS_ENDPOINT_URL,
                data_points=[RackTimeSeriesDataPoint.from_dict(
                    {
                        "name": x["name"],
                        "unit": x["unit"],
                        "granularity_seconds": GRANULARITY_IN_SECONDS,
                        "labels": {
                            "facility_id": rack_create.facility_id,
                            "rack_id": rack_id,
                            "country_code": "XXX"
                        }
                    })
                    for x in [
                        {
                            "name": "inlet_temperature_celsius",
                            "unit": "Temperature"
                        },
                        {
                            "name": "outlet_temperature_celsius",
                            "unit": "Temperature"
                        }
                    ]+[{"name": f"pdu_{n}_energy_consumption_joules", "unit": "Energy"} for n in range(1, rack_create.number_of_pdus+1)]
                ]
            )
        )

        with engine.connect() as conn:
            try:
                conn.execute(insert(racks).values({
                    "r_id":                                 resp.id,
                    "r_f_id":                               resp.facility_id,
                    "r_total_available_power":              resp.total_available_power,
                    "r_total_available_cooling_capacity":   resp.total_available_cooling_capacity,
                    "r_number_of_pdus":                     resp.number_of_pdus,
                    "r_power_redundancy":                   resp.power_redundancy,
                    "r_product_passport":                   json.dumps(resp.product_passport),
                    "r_prometheus_endpoint":                resp.time_series_config.endpoint,
                    "r_created_at":                         func.now(),
                    "r_updated_at":                         func.now()
                }))
            except IntegrityError as e:
                return Error(message="Integrity error", details="Does the given facility ID exist?", code=400), 400

            for t in resp.time_series_config.data_points:
                conn.execute(insert(racks_timeseries_configs).values({
                    "rtc_r_id": resp.id,
                    "rtc_name": t.name,
                    "rtc_unit": t.unit,
#                    "rtc_labels": json.dumps(t.labels),
                    "rtc_granularity_seconds": t.granularity_seconds
                }))
            conn.commit()
        return resp


    return 'do some magic!'


def delete_rack(rack_id):  # noqa: E501
    """Delete rack

    Remove a rack from the registry # noqa: E501

    :param rack_id: Unique rack identifier (format RACK-[FACILITY_ID]-[RACK_ID])
    :type rack_id: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    return 'do some magic!'


def get_rack(rack_id):  # noqa: E501
    """Get rack details

    Retrieve detailed information about a specific rack # noqa: E501

    :param rack_id: Unique rack identifier (format RACK-[FACILITY_ID]-[RACK_ID])
    :type rack_id: str

    :rtype: Union[RackResponse, Tuple[RackResponse, int], Tuple[RackResponse, int, Dict[str, str]]
    """
    return 'do some magic!'


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
    return 'do some magic!'


def query_rack_metrics(rack_id, rack_metrics_query):  # noqa: E501
    """Query rack metrics

    Retrieve aggregated time series metrics for a rack over a specified time period # noqa: E501

    :param rack_id: Unique rack identifier (format RACK-[FACILITY_ID]-[RACK_ID])
    :type rack_id: str
    :param rack_metrics_query: 
    :type rack_metrics_query: dict | bytes

    :rtype: Union[RackMetricsQueryResponse, Tuple[RackMetricsQueryResponse, int], Tuple[RackMetricsQueryResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        rack_metrics_query = RackMetricsQuery.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


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
