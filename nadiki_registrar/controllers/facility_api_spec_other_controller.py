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

from uuid import uuid4
from sqlalchemy import create_engine, text, MetaData, Table, select, delete, insert

engine = create_engine("mysql+pymysql://root:toogood4u@localhost/nadiki_registrar?charset=utf8mb4")
meta = MetaData()
meta.reflect(engine)
facilities = Table("facilities", meta, autoload_with=engine)

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
        resp.design_pue = 7
        resp.id = uuid4()
        resp.country_code = "de"
        resp.time_series_config = {
            "endpoint": "https://mdkdasdmkldsa"
        }
        with engine.connect() as conn:
            conn.execute(insert(facilities).values({"id": resp.id}))
            conn.commit()
        return resp

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
