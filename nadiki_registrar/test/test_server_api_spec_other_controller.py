# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_servers200_response import ListServers200Response  # noqa: E501
from nadiki_registrar.models.server_create import ServerCreate  # noqa: E501
from nadiki_registrar.models.server_response import ServerResponse  # noqa: E501
from nadiki_registrar.models.server_update import ServerUpdate  # noqa: E501
from nadiki_registrar.test import BaseTestCase

from nadiki_registrar.test.helpers import *


class TestServerApiSpecOtherController(BaseTestCase):
    """ServerApiSpecOtherController integration test stubs"""

    def test_create_server(self):
        """Test case for create_server

        Register a new server
        """
        facility_input = create_facility_input()
        facility_response = create_facility_raw(self.client, facility_input)
        decoded_facility_response = facility_response.data.decode('utf-8')
        facility_response_dict = json.loads(decoded_facility_response)
        rack_input = create_rack_input(facility_response_dict["id"])
        rack_response = create_rack_raw(self.client, rack_input)
        decoded_rack_response = rack_response.data.decode('utf-8')
        rack_response_dict = json.loads(decoded_rack_response)

        server_input = create_server_input(facility_response_dict["id"], rack_response_dict["id"])
        server_response = create_server_raw(self.client, server_input)
        self._check_server_response(server_response)

    def _check_server_response(self, response):
        self.assertEqual(response.status_code, 201,
                       'Response body is : ' + response.data.decode('utf-8'))
        decoded_server_response = response.data.decode('utf-8')
        server_response_dict = json.loads(decoded_server_response)

        return server_response_dict

    def test_delete_server(self):
        """Test case for delete_server

        Delete server
        """
        facility_input = create_facility_input()
        facility_response = create_facility_raw(self.client, facility_input)
        decoded_facility_response = facility_response.data.decode('utf-8')
        facility_response_dict = json.loads(decoded_facility_response)
        rack_input = create_rack_input(facility_response_dict["id"])
        rack_response = create_rack_raw(self.client, rack_input)
        decoded_rack_response = rack_response.data.decode('utf-8')
        rack_response_dict = json.loads(decoded_rack_response)

        server_input = create_server_input(facility_response_dict["id"], rack_response_dict["id"])
        server_response = create_server_raw(self.client, server_input)
        server_response_dict = self._check_server_response(server_response)

        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/servers/{server_id}'.format(server_id=server_response_dict["id"]),
            method='DELETE',
            headers=headers)
        self.assertEqual(response.status_code, 204,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_get_server(self):
        """Test case for get_server

        Get server details
        """
        facility_input = create_facility_input()
        facility_response = create_facility_raw(self.client, facility_input)
        decoded_facility_response = facility_response.data.decode('utf-8')
        facility_response_dict = json.loads(decoded_facility_response)
        rack_input = create_rack_input(facility_response_dict["id"])
        rack_response = create_rack_raw(self.client, rack_input)
        decoded_rack_response = rack_response.data.decode('utf-8')
        rack_response_dict = json.loads(decoded_rack_response)

        server_input = create_server_input(facility_response_dict["id"], rack_response_dict["id"])
        server_response = create_server_raw(self.client, server_input)
        server_response_dict = self._check_server_response(server_response)

        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/servers/{server_id}'.format(server_id=server_response_dict["id"]),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

#    def test_list_servers(self):
#        """Test case for list_servers
#
#        List all servers
#        """
#        query_string = [('limit', 20),
#                        ('offset', 0),
#                        ('facility_id', 'facility_id_example'),
#                        ('rack_id', 'rack_id_example')]
#        headers = { 
#            'Accept': 'application/json',
#        }
#        response = self.client.open(
#            '/v1/servers',
#            method='GET',
#            headers=headers,
#            query_string=query_string)
#        self.assert200(response,
#                       'Response body is : ' + response.data.decode('utf-8'))
#
#
#    def test_update_server(self):
#        """Test case for update_server
#
#        Update server
#        """
#        server_update = null
#        headers = { 
#            'Accept': 'application/json',
#            'Content-Type': 'application/json',
#        }
#        response = self.client.open(
#            '/v1/servers/{server_id}'.format(server_id='server_id_example'),
#            method='PUT',
#            headers=headers,
#            data=json.dumps(server_update),
#            content_type='application/json')
#        self.assert200(response,
#                       'Response body is : ' + response.data.decode('utf-8'))
#

if __name__ == '__main__':
    unittest.main()
