# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

from datetime import datetime

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_racks200_response import ListRacks200Response  # noqa: E501
from nadiki_registrar.models.rack_create import RackCreate  # noqa: E501
from nadiki_registrar.models.rack_response import RackResponse  # noqa: E501
from nadiki_registrar.models.rack_update import RackUpdate  # noqa: E501
from nadiki_registrar.test import BaseTestCase

from nadiki_registrar.test.helpers import *

class TestRackApiSpecOtherController(BaseTestCase):
    """RackApiSpecOtherController integration test stubs"""

    def test_create_rack(self):
        """Test case for create_rack

        Register a new rack
        """

        facility_input = create_facility_input()
        facility_response = create_facility_raw(self.client, facility_input)
        decoded_facility_response = facility_response.data.decode('utf-8')
        facility_response_dict = json.loads(decoded_facility_response)
        rack_input = create_rack_input(facility_response_dict["id"])
        rack_response = create_rack_raw(self.client, rack_input)
        self._check_rack_response(rack_input, rack_response, 201)


    def _check_rack_response(self, input, response, expected_code):
        decoded_response = response.data.decode('utf-8')
        self.assertEqual(response.status_code, expected_code,
                       'Response body is : ' + decoded_response)
        self.assertTrue(len(decoded_response) > 0)
        response_dict = json.loads(decoded_response)
        for k in input:
            if type(input[k]) != dict:
                self.assertEqual(str(response_dict[k]), str(input[k]), f"Property {k} does not match the input")

        self.assertTrue(len(response_dict["createdAt"]) > 0,                        "no createdAt in output")
        self.assertTrue(len(response_dict["updatedAt"]) > 0,                        "no updatedAt in output")
        self.assertEqual(response_dict["createdAt"], response_dict["updatedAt"],    "createdAt and updatedAt not equal for new rack")
        created_at = datetime.fromisoformat(response_dict["createdAt"])
        self.assertTrue(datetime.now().timestamp() - created_at.timestamp() < 10,   "createdAt is more than 10 seconds ago for new rack")


        self.assertTrue(len(response_dict["id"]) > 0,          "no id in output")
        self.assertTrue(len(response_dict["facility_id"]) > 0, "no facility_id in output")

        for d in response_dict["timeSeriesConfig"]["dataPoints"]:
#            self.assertEqual(d["labels"]["country_code"], response_dict["countryCode"], "label country_code does not match country_code")
            self.assertEqual(d["labels"]["rack_id"],  response_dict["id"], "label rack_id does not match rack_id")

        return response_dict


    def test_delete_rack(self):
        """Test case for delete_rack

        Delete rack
        """
        facility_input = create_facility_input()
        facility_response = create_facility_raw(self.client, facility_input)
        decoded_facility_response = facility_response.data.decode('utf-8')
        facility_response_dict = json.loads(decoded_facility_response)
        rack_input = create_rack_input(facility_response_dict["id"])
        rack_response = create_rack_raw(self.client, rack_input)
        rack_response_dict = self._check_rack_response(rack_input, rack_response, 201)

        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/racks/{rack_id}'.format(rack_id=rack_response_dict["id"]),
            method='DELETE',
            headers=headers)
        self.assertEqual(response.status_code, 204,
                       'Response body is : ' + response.data.decode('utf-8'))
        response = self.client.open(
            '/v1/racks/{rack_id}'.format(rack_id=rack_response_dict["id"]),
            method='DELETE',
            headers=headers)
        self.assertEqual(response.status_code, 404,
                       'Second DELETE should fail, response body is : ' + response.data.decode('utf-8'))

    def test_get_rack(self):
        """Test case for get_rack

        Get rack details
        """

        facility_input = create_facility_input()
        facility_response = create_facility_raw(self.client, facility_input)
        decoded_facility_response = facility_response.data.decode('utf-8')
        facility_response_dict = json.loads(decoded_facility_response)
        rack_input = create_rack_input(facility_response_dict["id"])
        rack_response = create_rack_raw(self.client, rack_input)
        rack_response_dict = self._check_rack_response(rack_input, rack_response, 201)

        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/racks/{rack_id}'.format(rack_id=rack_response_dict["id"]),
            method='GET',
            headers=headers)
        self._check_rack_response(rack_input, response, 200)


    def test_list_racks(self):
        """Test case for list_racks

        List all racks
        """
        query_string = [('limit', 20),
                        ('offset', 0),
                        ('facility_id', 'facility_id_example')]
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/racks',
            method='GET',
            headers=headers,
            query_string=query_string)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))
#
#
#    def test_update_rack(self):
#        """Test case for update_rack
#
#        Update rack
#        """
#        rack_update = null
#        headers = { 
#            'Accept': 'application/json',
#            'Content-Type': 'application/json',
#        }
#        response = self.client.open(
#            '/v1/racks/{rack_id}'.format(rack_id='RACK-FACILITY-DEU-099-099'),
#            method='PUT',
#            headers=headers,
#            data=json.dumps(rack_update),
#            content_type='application/json')
#        self.assert200(response,
#                       'Response body is : ' + response.data.decode('utf-8'))
#

if __name__ == '__main__':
    unittest.main()
