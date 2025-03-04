# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_servers200_response import ListServers200Response  # noqa: E501
from nadiki_registrar.models.server_create import ServerCreate  # noqa: E501
from nadiki_registrar.models.server_metrics_query import ServerMetricsQuery  # noqa: E501
from nadiki_registrar.models.server_metrics_query_response import ServerMetricsQueryResponse  # noqa: E501
from nadiki_registrar.models.server_response import ServerResponse  # noqa: E501
from nadiki_registrar.models.server_update import ServerUpdate  # noqa: E501
from nadiki_registrar.test import BaseTestCase


class TestServerApiSpecOtherController(BaseTestCase):
    """ServerApiSpecOtherController integration test stubs"""

    def test_create_server(self):
        """Test case for create_server

        Register a new server
        """
        server_create = {"number_of_psus":1,"rated_power":0.8008282,"installed_gpus":[{"vendor":"vendor","type":"type"},{"vendor":"vendor","type":"type"}],"total_fpgas":0,"hard_disks":[{"vendor":"vendor","type":"NVMe","capacity":2.302136},{"vendor":"vendor","type":"NVMe","capacity":2.302136}],"total_cpu_sockets":1,"total_gpus":0,"total_installed_memory":5,"cooling_type":"air","rack_id":"rack_id","installed_fpgas":[{"vendor":"vendor","type":"type"},{"vendor":"vendor","type":"type"}],"product_passport":"{}","installed_cpus":[{"vendor":"vendor","type":"type"},{"vendor":"vendor","type":"type"}],"facility_id":"facility_id","number_of_memory_units":5}
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/servers',
            method='POST',
            headers=headers,
            data=json.dumps(server_create),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_delete_server(self):
        """Test case for delete_server

        Delete server
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/servers/{server_id}'.format(server_id='server_id_example'),
            method='DELETE',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_get_server(self):
        """Test case for get_server

        Get server details
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/servers/{server_id}'.format(server_id='server_id_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_list_servers(self):
        """Test case for list_servers

        List all servers
        """
        query_string = [('limit', 20),
                        ('offset', 0),
                        ('facility_id', 'facility_id_example'),
                        ('rack_id', 'rack_id_example')]
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/servers',
            method='GET',
            headers=headers,
            query_string=query_string)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_query_server_metrics(self):
        """Test case for query_server_metrics

        Query server metrics
        """
        server_metrics_query = {"startTime":"2000-01-23T04:56:07.000+00:00","aggregation":"sum","endTime":"2000-01-23T04:56:07.000+00:00","metrics":["metrics","metrics"]}
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/servers/{server_id}/query'.format(server_id='server_id_example'),
            method='POST',
            headers=headers,
            data=json.dumps(server_metrics_query),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_update_server(self):
        """Test case for update_server

        Update server
        """
        server_update = null
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/servers/{server_id}'.format(server_id='server_id_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(server_update),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
