import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_servers200_response import ListServers200Response  # noqa: E501
from nadiki_registrar.models.server_create import ServerCreate  # noqa: E501
from nadiki_registrar.models.server_metrics_query import ServerMetricsQuery  # noqa: E501
from nadiki_registrar.models.server_metrics_query_response import ServerMetricsQueryResponse  # noqa: E501
from nadiki_registrar.models.server_response import ServerResponse  # noqa: E501
from nadiki_registrar.models.server_update import ServerUpdate  # noqa: E501
from nadiki_registrar import util

import json

from sqlalchemy import create_engine, MetaData, Table, select, delete, insert, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func

from nadiki_registrar.controllers.config import *
from nadiki_registrar.controllers.database import *
from nadiki_registrar.controllers.identifiers import RackId
from nadiki_registrar.controllers.identifiers import ServerId

def create_server(server_create=None):  # noqa: E501
    """Register a new server

    Create a new server entry in the registry # noqa: E501

    :param server_create: 
    :type server_create: dict | bytes

    :rtype: Union[ServerResponse, Tuple[ServerResponse, int], Tuple[ServerResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        server_create = ServerCreate.from_dict(connexion.request.get_json())  # noqa: E501

        rack_id = RackId.fromString(server_create.rack_id)

        with engine.connect() as conn:
            conn.execute(insert(servers).values({
                "s_r_id":                   rack_id.number,
                "s_rated_power":            server_create.rated_power,
                "s_total_cpu_sockets":      server_create.total_cpu_sockets,
                "s_number_of_psus":         server_create.number_of_psus,
                "s_total_installed_memory": server_create.total_installed_memory,
                "s_number_of_memory_units": server_create.number_of_memory_units,
                "s_total_gpus":             server_create.total_gpus,
                "s_total_fpgas":            server_create.total_fpgas,
                "s_product_passport":       json.dumps(server_create.product_passport),
                "s_cooling_type":           server_create.cooling_type,
                "s_created_at":             func.now(),
                "s_updated_at":             func.now(),
            }))

            result = conn.execute(text("SELECT LAST_INSERT_ID() AS id FROM servers"));
            id = next(result).id

            conn.commit()
        
        return get_server(ServerId(server_create.rack_id, id).toString())


def delete_server(server_id):  # noqa: E501
    """Delete server

    Remove a server from the registry # noqa: E501

    :param server_id: Unique server identifier (format SERVER-[FACILITY_ID]-[RACK_ID]-[SERVER_ID])
    :type server_id: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    return 'do some magic!'


def get_server(server_id):  # noqa: E501
    """Get server details

    Retrieve detailed information about a specific server # noqa: E501

    :param server_id: Unique server identifier (format SERVER-[FACILITY_ID]-[RACK_ID]-[SERVER_ID])
    :type server_id: str

    :rtype: Union[ServerResponse, Tuple[ServerResponse, int], Tuple[ServerResponse, int, Dict[str, str]]
    """
    
    srvid = ServerId.fromString(server_id)
    with engine.connect() as conn:
        result = conn.execute(select(servers).where(servers.c.s_id == srvid.number))
        return _create_server_response(next(result))


def _create_server_response(row):
    return ServerResponse(
        id                      = row.s_id,
        rated_power             = row.s_rated_power,
        total_cpu_sockets       = row.s_total_cpu_sockets,
        number_of_psus          = row.s_number_of_psus,
        total_installed_memory  = row.s_total_installed_memory,
        number_of_memory_units  = row.s_number_of_memory_units,
        total_gpus              = row.s_total_gpus,
        total_fpgas             = row.s_total_fpgas,
        product_passport        = row.s_product_passport,
        cooling_type            = row.s_cooling_type
    )

def list_servers(limit=None, offset=None, facility_id=None, rack_id=None):  # noqa: E501
    """List all servers

    Retrieve a list of all registered servers # noqa: E501

    :param limit: Maximum number of servers to return
    :type limit: int
    :param offset: Number of servers to skip
    :type offset: int
    :param facility_id: Filter servers by facility ID
    :type facility_id: str
    :param rack_id: Filter servers by rack ID
    :type rack_id: str

    :rtype: Union[ListServers200Response, Tuple[ListServers200Response, int], Tuple[ListServers200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def query_server_metrics(server_id, server_metrics_query):  # noqa: E501
    """Query server metrics

    Retrieve aggregated time series metrics for a server over a specified time period # noqa: E501

    :param server_id: Unique server identifier (format SERVER-[FACILITY_ID]-[RACK_ID]-[SERVER_ID])
    :type server_id: str
    :param server_metrics_query: 
    :type server_metrics_query: dict | bytes

    :rtype: Union[ServerMetricsQueryResponse, Tuple[ServerMetricsQueryResponse, int], Tuple[ServerMetricsQueryResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        server_metrics_query = ServerMetricsQuery.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def update_server(server_id, server_update):  # noqa: E501
    """Update server

    Update all server information # noqa: E501

    :param server_id: Unique server identifier (format SERVER-[FACILITY_ID]-[RACK_ID]-[SERVER_ID])
    :type server_id: str
    :param server_update: 
    :type server_update: dict | bytes

    :rtype: Union[ServerResponse, Tuple[ServerResponse, int], Tuple[ServerResponse, int, Dict[str, str]]
    """
    if connexion.request.is_json:
        server_update = ServerUpdate.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'
