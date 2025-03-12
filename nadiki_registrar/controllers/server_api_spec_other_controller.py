import connexion
import six
from typing import Dict
from typing import Tuple
from typing import Union

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_servers200_response import ListServers200Response  # noqa: E501
from nadiki_registrar.models.server_create import ServerCreate  # noqa: E501
from nadiki_registrar.models.server_response import ServerResponse  # noqa: E501
from nadiki_registrar.models.server_update import ServerUpdate  # noqa: E501
from nadiki_registrar import util

from nadiki_registrar.models.cpu import CPU  # noqa: E501
from nadiki_registrar.models.gpu import GPU  # noqa: E501
from nadiki_registrar.models.fpga import FPGA  # noqa: E501
from nadiki_registrar.models.storage_device import StorageDevice  # noqa: E501
from nadiki_registrar.models.server_time_series_config import ServerTimeSeriesConfig  # noqa: E501
from nadiki_registrar.models.server_time_series_data_point import ServerTimeSeriesDataPoint  # noqa: E501

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
                "s_product_passport":       json.dumps(server_create.product_passport),
                "s_cooling_type":           server_create.cooling_type,
                "s_prometheus_endpoint":    PROMETHEUS_ENDPOINT_URL,
                "s_created_at":             func.now(),
                "s_updated_at":             func.now(),
            }))

            result = conn.execute(text("SELECT LAST_INSERT_ID() AS id FROM servers"));
            id = next(result).id

            for t in [
                {
                    "name": "cpu_energy_consumption_joules",
                    "unit": "Energy"
                },
                {
                    "name": "server_energy_consumption_joules",
                    "unit": "Energy"
                }]:

                conn.execute(insert(servers_timeseries_configs).values({
                    "stc_s_id": id,
                    "stc_name": t["name"],
                    "stc_unit": t["unit"],
                    "stc_granularity_seconds": GRANULARITY_IN_SECONDS,
                    "stc_labels": json.dumps({
                        "facility_id": server_create.facility_id,
                        "rack_id": server_create.rack_id,
                        "country_code": rack_id.facility.country_code
                    })
                }))

            for cpu in server_create.installed_cpus:
                conn.execute(insert(servers_cpus).values({
                    "sc_s_id": id,
                    "sc_vendor": cpu.vendor,
                    "sc_type": cpu.type
                }))

            for gpu in server_create.installed_gpus:
                conn.execute(insert(servers_gpus).values({
                    "sg_s_id": id,
                    "sg_vendor": gpu.vendor,
                    "sg_type": gpu.type
                }))

            for fpga in server_create.installed_fpgas:
                conn.execute(insert(servers_fpgas).values({
                    "sf_s_id": id,
                    "sf_vendor": fpga.vendor,
                    "sf_type": fpga.type
                }))

            for hd in server_create.storage_devices:
                conn.execute(insert(servers_storage_devices).values({
                    "sh_s_id": id,
                    "sh_vendor": hd.vendor,
                    "sh_type": hd.type
                }))

            conn.commit()
        
        return get_server(ServerId(server_create.rack_id, id).toString()), 201


def delete_server(server_id):  # noqa: E501
    """Delete server

    Remove a server from the registry # noqa: E501

    :param server_id: Unique server identifier (format SERVER-[FACILITY_ID]-[RACK_ID]-[SERVER_ID])
    :type server_id: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    
    srvid = ServerId.fromString(server_id)
    with engine.connect() as conn:
        result = conn.execute(delete(servers).where(servers.c.s_id == srvid.number and servers.c.s_r_id == srvid.rack.number))
        conn.commit()
        if result.rowcount == 1:
            return "Server deleted", 204
        else:
            return Error(code=404, message="Server not found"), 404


def get_server(server_id):  # noqa: E501
    """Get server details

    Retrieve detailed information about a specific server # noqa: E501

    :param server_id: Unique server identifier (format SERVER-[FACILITY_ID]-[RACK_ID]-[SERVER_ID])
    :type server_id: str

    :rtype: Union[ServerResponse, Tuple[ServerResponse, int], Tuple[ServerResponse, int, Dict[str, str]]
    """
    
    srvid = ServerId.fromString(server_id)
    with engine.connect() as conn:
        servers_result = conn.execute(select(servers).where(servers.c.s_id == srvid.number))
        servers_timeseries_configs_result = conn.execute(select(servers_timeseries_configs).where(servers_timeseries_configs.c.stc_s_id == srvid.number))
        servers_cpus_result = conn.execute(select(servers_cpus).where(servers_cpus.c.sc_s_id == srvid.number))
        servers_gpus_result = conn.execute(select(servers_gpus).where(servers_gpus.c.sg_s_id == srvid.number))
        servers_fpgas_result = conn.execute(select(servers_fpgas).where(servers_fpgas.c.sf_s_id == srvid.number))
        servers_storage_devices_result = conn.execute(select(servers_storage_devices).where(servers_storage_devices.c.sh_s_id == srvid.number))

        return _create_server_response(next(servers_result), servers_timeseries_configs_result, servers_cpus_result, servers_gpus_result, servers_fpgas_result, servers_storage_devices_result)

def _create_server_response(row, servers_timeseries_configs, servers_cpus_result, servers_gpus_result, servers_fpgas_result, servers_storage_devices_result):
    return ServerResponse(
        id                      = row.s_id,
        rated_power             = row.s_rated_power,
        total_cpu_sockets       = row.s_total_cpu_sockets,
        number_of_psus          = row.s_number_of_psus,
        total_installed_memory  = row.s_total_installed_memory,
        number_of_memory_units  = row.s_number_of_memory_units,
        product_passport        = row.s_product_passport,
        cooling_type            = row.s_cooling_type,
        time_series_config      = ServerTimeSeriesConfig(endpoint=row.s_prometheus_endpoint, data_points=[ServerTimeSeriesDataPoint(
            name                = x.stc_name,
            unit                = x.stc_unit,
            granularity_seconds = x.stc_granularity_seconds,
            labels              = json.loads(x.stc_labels)) for x in servers_timeseries_configs]
        ),
        installed_cpus          = [CPU(vendor=x.sc_vendor, type=x.sc_type) for x in servers_cpus_result],
        installed_gpus          = [GPU(vendor=x.sg_vendor, type=x.sg_type) for x in servers_gpus_result],
        installed_fpgas         = [FPGA(vendor=x.sf_vendor, type=x.sf_type) for x in servers_fpgas_result],
        storage_devices         = [StorageDevice(vendor=x.sh_vendor, type=x.sh_type) for x in servers_storage_devices_result],
        created_at              = row.s_created_at,
        updated_at              = row.s_updated_at
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

    result = []
    with engine.connect() as conn:
        servers_result = conn.execute(select(servers).limit(limit).offset(offset))
        
        for x in servers_result:
            servers_timeseries_configs_result = conn.execute(select(servers_timeseries_configs).where(servers_timeseries_configs.c.stc_s_id == x.s_id))
            servers_cpus_result = conn.execute(select(servers_cpus).where(servers_cpus.c.sc_s_id == x.s_id))
            servers_gpus_result = conn.execute(select(servers_gpus).where(servers_gpus.c.sg_s_id == x.s_id))
            servers_fpgas_result = conn.execute(select(servers_fpgas).where(servers_fpgas.c.sf_s_id == x.s_id))
            servers_storage_devices_result = conn.execute(select(servers_storage_devices).where(servers_storage_devices.c.sh_s_id == x.s_id))
            result.append(_create_server_response(x, servers_timeseries_configs_result, servers_cpus_result, servers_gpus_result, servers_fpgas_result, servers_storage_devices_result))

        return ListServers200Response(items=result, total=servers_result.rowcount, limit=limit, offset=offset)


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
