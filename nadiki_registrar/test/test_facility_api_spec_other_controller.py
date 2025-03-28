# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

from pprint import pformat

from datetime import datetime

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.facility_create import FacilityCreate  # noqa: E501
from nadiki_registrar.models.facility_response import FacilityResponse  # noqa: E501
from nadiki_registrar.models.facility_update import FacilityUpdate  # noqa: E501
from nadiki_registrar.models.list_facilities200_response import ListFacilities200Response  # noqa: E501
from nadiki_registrar.test import BaseTestCase

from nadiki_registrar.test.helpers import *

class TestFacilityApiSpecOtherController(BaseTestCase):
    """FacilityApiSpecOtherController integration test stubs"""


    def test_create_facility(self):
        """Test case for create_facility

        Register a new facility
        """

        input = create_facility_input()
        response = create_facility_raw(self.client, input)
        self._check_facility_response(input, response, 201)


    def _check_facility_response(self, input, response, expected_code):
        decoded_response = response.data.decode('utf-8')
        self.assertEqual(response.status_code, expected_code,
                       'Response body is : ' + decoded_response)
        self.assertTrue(len(decoded_response) > 0)
        response_dict = json.loads(decoded_response)
        for k in input:
            if type(input[k]) != dict:
                self.assertEqual(str(response_dict[k]), str(input[k]), f"Property {k} does not match the input")

        self.assertTrue(len(response_dict["id"]) > 0,                               "no id in output")
        self.assertTrue(len(response_dict["createdAt"]) > 0,                        "no createdAt in output")
        self.assertTrue(len(response_dict["updatedAt"]) > 0,                        "no updatedAt in output")
        self.assertTrue(datetime.fromisoformat(response_dict["createdAt"]).timestamp() <= datetime.fromisoformat(response_dict["updatedAt"]).timestamp(),
                        "createdAt not less than or equal to updatedAt")
        created_at = datetime.fromisoformat(response_dict["createdAt"])
        self.assertTrue(datetime.now().timestamp() - created_at.timestamp() < 10,   "createdAt is more than 10 seconds ago for new facility")
        self.assertTrue(len(response_dict["countryCode"]) > 0,                      "no country code in output")
        self.assertTrue(len(response_dict["timeSeriesConfig"]["dataPoints"]) > 0,   "no data points in output")

        for d in response_dict["timeSeriesConfig"]["dataPoints"]:
            self.assertEqual(d["tags"]["country_code"], response_dict["countryCode"], "tag country_code does not match country_code")
            self.assertEqual(d["tags"]["facility_id"], response_dict["id"], "tag facility_id does not match facility_id")

        return response_dict


    def test_delete_facility(self):
        """Test case for delete_facility

        Delete facility
        """

        input = create_facility_input()
        response = create_facility_raw(self.client, input)
        response_dict = self._check_facility_response(input, response, 201)

        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities/{facility_id}'.format(facility_id=response_dict["id"]),
            method='DELETE',
            headers=headers)
        self.assertEqual(response.status_code, 204,
                       'Response body is : ' + response.data.decode('utf-8'))
        response = self.client.open(
            '/v1/facilities/{facility_id}'.format(facility_id=response_dict["id"]),
            method='DELETE',
            headers=headers)
        self.assertEqual(response.status_code, 404,
                       'Second DELETE should fail, response body is : ' + response.data.decode('utf-8'))
 

    def test_get_facility(self):
        """Test case for get_facility
 
        Get facility details
        """
        input = create_facility_input()
        response = create_facility_raw(self.client, input)
        decoded_response = response.data.decode('utf-8')
        self.assertEqual(response.status_code, 201,
                       'Response body is : ' + decoded_response)
        self.assertTrue(len(decoded_response) > 0)
        response_dict = json.loads(decoded_response)

        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities/{facility_id}'.format(facility_id=response_dict["id"]),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))
        self._check_facility_response(input, response, 200)


    def test_list_facilities(self):
        """Test case for list_facilities

        List all facilities
        """
        query_string = [('limit', 20),
                        ('offset', 0)]
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities',
            method='GET',
            headers=headers,
            query_string=query_string)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


    def test_update_facility(self):
        """Test case for update_facility

        Update facility
        """
        input = create_facility_input()
        response = create_facility_raw(self.client, input)
        response_dict = self._check_facility_response(input, response, 201)

        facility_update = create_facility_input()
        headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities/{facility_id}'.format(facility_id=response_dict["id"]),
            method='PUT',
            headers=headers,
            data=json.dumps(facility_update),
            content_type='application/json')
        self._check_facility_response(facility_update, response, 200)


if __name__ == '__main__':
    unittest.main()
