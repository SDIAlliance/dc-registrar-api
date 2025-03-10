# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.facility_create import FacilityCreate  # noqa: E501
from nadiki_registrar.models.facility_metrics_query import FacilityMetricsQuery  # noqa: E501
from nadiki_registrar.models.facility_metrics_query_response import FacilityMetricsQueryResponse  # noqa: E501
from nadiki_registrar.models.facility_response import FacilityResponse  # noqa: E501
from nadiki_registrar.models.facility_update import FacilityUpdate  # noqa: E501
from nadiki_registrar.models.list_facilities200_response import ListFacilities200Response  # noqa: E501
from nadiki_registrar.test import BaseTestCase


class TestFacilityApiSpecOtherController(BaseTestCase):
    """FacilityApiSpecOtherController integration test stubs"""

    def test_create_facility(self):
        """Test case for create_facility

        Register a new facility
        """
        facility_create = {
            "embeddedGhgEmissionsFacility":1.4658129,
            "maintenanceHoursGenerator":3.6160767,
            "whiteSpace":6.846853,
            "designPue":1.7386281,
            "coolingFluids": [
                {
                    "amount":7.0614014,
                    "gwpFactor":9.301444,
                    "type":"type"
                },
                {
                    "amount":7.0614014,
                    "gwpFactor":9.301444,
                    "type":"type"
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
                "latitude":48.13715,
                "longitude":11.5761236
            },
            "embeddedGhgEmissionsAssets":5.637377
        }
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities',
            method='POST',
            headers=headers,
            data=json.dumps(facility_create),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

#    def test_delete_facility(self):
#        """Test case for delete_facility
#
#        Delete facility
#        """
#        headers = { 
#            'Accept': 'application/json',
#        }
#        response = self.client.open(
#            '/v1/facilities/{facility_id}'.format(facility_id='FACILITY-DEU-099'),
#            method='DELETE',
#            headers=headers)
#        self.assert200(response,
#                       'Response body is : ' + response.data.decode('utf-8'))

    def test_get_facility(self):
        """Test case for get_facility

        Get facility details
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities/{facility_id}'.format(facility_id='FACILITY-DEU-099'),
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

#    def test_query_facility_metrics(self):
#        """Test case for query_facility_metrics
#
#        Query facility metrics
#        """
#        facility_metrics_query = {"startTime":"2000-01-23T04:56:07.000+00:00","aggregation":"sum","endTime":"2000-01-23T04:56:07.000+00:00","metrics":["heatpump_power_consumption_joules","heatpump_power_consumption_joules"]}
#        headers = { 
#            'Accept': 'application/json',
#            'Content-Type': 'application/json',
#        }
#        response = self.client.open(
#            '/v1/facilities/{facility_id}/query'.format/facility_id='FACILITY-DEU-099'),
#            method='POST',
#            headers=headers,
#            data=json.dumps(facility_metrics_query),
#            content_type='application/json')
#        self.assert200(response,
#                       'Response body is : ' + response.data.decode('utf-8'))

    def test_update_facility(self):
        """Test case for update_facility

        Update facility
        """
        facility_update = null
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/facilities/{facility_id}'.format(facility_id='FACILITY-DEU-099'),
            method='PUT',
            headers=headers,
            data=json.dumps(facility_update),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
