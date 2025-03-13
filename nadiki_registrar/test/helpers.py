import json
import random
import math

random.seed()

def __truncated_random_float(order_of_magnitude=10, digits=9, minimum=0):
    return math.floor((minimum+random.random()*order_of_magnitude)*10**digits)/10**digits

def create_facility_input():
    rnd = random.Random()
    facility_create = {
        "embeddedGhgEmissionsFacility": __truncated_random_float(),
        "maintenanceHoursGenerator": __truncated_random_float(),
        "whiteSpace": __truncated_random_float(),
        "designPue": __truncated_random_float(minimum=1),
        "coolingFluids": [
            {
                "amount": __truncated_random_float(),
                "gwpFactor": __truncated_random_float(),
                "type":"beer"
            },
            {
                "amount": __truncated_random_float(),
                "gwpFactor": __truncated_random_float(),
                "type":"water"
            }
        ],
        "totalSpace": __truncated_random_float(),
        "gridPowerFeeds":1,
        "lifetimeFacility":1,
        "whiteSpaceFloors":1,
        "installedCapacity": __truncated_random_float(),
        "lifetimeAssets":1,
        "tierLevel":1,
        "location": {
            "latitude":48.13715+rnd.random(), # prevent conflicts because location must be unique
            "longitude":11.5761236+rnd.random()
        },
        "embeddedGhgEmissionsAssets": __truncated_random_float()
    }
    return facility_create


def create_facility_raw(client, input):
    headers = { 
        'Accept': 'application/json',
        'Content-Type': 'application/json',
    }
    return client.open(
        '/v1/facilities',
        method='POST',
        headers=headers,
        data=json.dumps(input),
        content_type='application/json')

def create_rack_input(facility_id):
    rack_create = {
        "total_available_cooling_capacity": 6.0274563,
        "total_available_power": 0.8008282,
        "number_of_pdus": 1,
        "product_passport":{},
        "power_redundancy": 1,
        "facility_id": facility_id
    }
    return rack_create

def create_rack_raw(client, input):
    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
    }
    return client.open(
        '/v1/racks',
        method='POST',
        headers=headers,
        data=json.dumps(input),
        content_type='application/json')

def create_server_input(facility_id, rack_id):
    server_create = {
        "number_of_psus": 1,
        "rated_power": 0.8008282,
        "installed_gpus": [
            {"vendor":"vendor","type":"type"},
            {"vendor":"vendor","type":"type"}
        ],
        "storage_devices": [
            {"vendor":"vendor","type":"NVMe","capacity":2.302136},
            {"vendor":"vendor","type":"NVMe","capacity":2.302136}
        ],
        "total_cpu_sockets": 1,
        "total_installed_memory": 5,
        "cooling_type": "air",
        "rack_id": rack_id,
        "installed_fpgas": [
            {"vendor":"vendor","type":"type"},
            {"vendor":"vendor","type":"type"}
        ],
        "product_passport":{},
        "installed_cpus": [
            {"vendor":"vendor","type":"type"},
            {"vendor":"vendor","type":"type"}
        ],
        "facility_id": facility_id,
        "number_of_memory_units": 5
    }
    return server_create

def create_server_raw(client, input):
    headers = { 
        'Accept': 'application/json',
        'Content-Type': 'application/json',
    }
    return client.open(
        '/v1/servers',
        method='POST',
        headers=headers,
        data=json.dumps(input),
        content_type='application/json')
