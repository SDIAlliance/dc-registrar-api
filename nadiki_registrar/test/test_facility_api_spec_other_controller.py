# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

import random
from pprint import pformat
from warnings import warn

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.facility_create import FacilityCreate  # noqa: E501
from nadiki_registrar.models.facility_response import FacilityResponse  # noqa: E501
from nadiki_registrar.models.facility_update import FacilityUpdate  # noqa: E501
from nadiki_registrar.models.list_facilities200_response import ListFacilities200Response  # noqa: E501
from nadiki_registrar.test import BaseTestCase

random.seed()

class TestFacilityApiSpecOtherController(BaseTestCase):
    """FacilityApiSpecOtherController integration test stubs"""

    def _create_facility_input(self):
        rnd = random.Random()
        facility_create = {
            "embeddedGhgEmissionsFacility":1.4658129,
            "maintenanceHoursGenerator":3.6160767,
            "whiteSpace":6.846853,
            "designPue":1.7386281,
            "coolingFluids": [
                {
                    "amount":7.0614014,
                    "gwpFactor":9.301444,
                    "type":"beer"
                },
                {
                    "amount":7.0614014,
                    "gwpFactor":9.301444,
                    "type":"water"
                }
            ],
            "totalSpace":1.4894159,
            "gridPowerFeeds":1,
            "lifetimeFacility":1,
            "whiteSpaceFloors":1,
            "installedCapacity":2.027123,
            "lifetimeAssets":1,
            "tierLevel":1,
            "location": {
                "latitude":48.13715+rnd.random(), # prevent conflicts because location must be unique
                "longitude":11.5761236+rnd.random()
            },
            "embeddedGhgEmissionsAssets":5.637377
        }
        return facility_create

    def _create_facility_raw(self, input):
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        return self.client.open(
            '/v1/facilities',
            method='POST',
            headers=headers,
            data=json.dumps(input),
            content_type='application/json')

    def test_create_facility(self):
        """Test case for create_facility

        Register a new facility
        """

        input = self._create_facility_input()
        response = self._create_facility_raw(input)
        decoded_response = response.data.decode('utf-8')
        self.assertEqual(response.status_code, 201,
                       'Response body is : ' + decoded_response)
        self.assertTrue(len(decoded_response) > 0)
        response_dict = json.loads(decoded_response)
        for k in input:
            if type(input[k]) != dict:
                self.assertEqual(str(response_dict[k]), str(input[k]))

        self.assertTrue(len(response_dict["id"]) > 0)
        self.assertTrue(len(response_dict["createdAt"]) > 0)
        self.assertTrue(len(response_dict["updatedAt"]) > 0)
        self.assertTrue(len(response_dict["countryCode"]) > 0)
        self.assertTrue(len(response_dict["timeSeriesConfig"]["dataPoints"]) > 0)

    def test_delete_facility(self):
        """Test case for delete_facility

        Delete facility
        """

        input = self._create_facility_input()
        response = self._create_facility_raw(input)
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
            method='DELETE',
            headers=headers)
        self.assertEquals(response.status_code, 204,
                       'Response body is : ' + response.data.decode('utf-8'))
 
    def test_get_facility(self):
        """Test case for get_facility
 
        Get facility details
        """
        input = self._create_facility_input()
        response = self._create_facility_raw(input)
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

#    def test_update_facility(self):
#        """Test case for update_facility
#
#        Update facility
#        """
#        facility_update = null
#        headers = { 
#            'Accept': 'application/json',
#            'Content-Type': 'application/json',
#        }
#        response = self.client.open(
#            '/v1/facilities/{facility_id}'.format(facility_id='FACILITY-DEU-099'),
#            method='PUT',
#            headers=headers,
#            data=json.dumps(facility_update),
#            content_type='application/json')
#        self.assert200(response,
#                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
