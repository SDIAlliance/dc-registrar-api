# coding: utf-8

from __future__ import absolute_import
import unittest

from flask import json
from six import BytesIO

from nadiki_registrar.models.error import Error  # noqa: E501
from nadiki_registrar.models.list_racks200_response import ListRacks200Response  # noqa: E501
from nadiki_registrar.models.rack_create import RackCreate  # noqa: E501
from nadiki_registrar.models.rack_metrics_query import RackMetricsQuery  # noqa: E501
from nadiki_registrar.models.rack_metrics_query_response import RackMetricsQueryResponse  # noqa: E501
from nadiki_registrar.models.rack_response import RackResponse  # noqa: E501
from nadiki_registrar.models.rack_update import RackUpdate  # noqa: E501
from nadiki_registrar.test import BaseTestCase


class TestRackApiSpecOtherController(BaseTestCase):
    """RackApiSpecOtherController integration test stubs"""

    def test_create_rack(self):
        """Test case for create_rack

        Register a new rack
        """
        rack_create = {"total_available_cooling_capacity":6.0274563,"total_available_power":0.8008282,"number_of_pdus":1,"product_passport":"{}","power_redundancy":1,"facility_id":"facility_id"}
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/racks',
            method='POST',
            headers=headers,
            data=json.dumps(rack_create),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_delete_rack(self):
        """Test case for delete_rack

        Delete rack
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/racks/{rack_id}'.format(rack_id='rack_id_example'),
            method='DELETE',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_get_rack(self):
        """Test case for get_rack

        Get rack details
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/v1/racks/{rack_id}'.format(rack_id='rack_id_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

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

    def test_query_rack_metrics(self):
        """Test case for query_rack_metrics

        Query rack metrics
        """
        rack_metrics_query = {"startTime":"2000-01-23T04:56:07.000+00:00","aggregation":"sum","endTime":"2000-01-23T04:56:07.000+00:00","metrics":["metrics","metrics"]}
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/racks/{rack_id}/query'.format(rack_id='rack_id_example'),
            method='POST',
            headers=headers,
            data=json.dumps(rack_metrics_query),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_update_rack(self):
        """Test case for update_rack

        Update rack
        """
        rack_update = null
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/v1/racks/{rack_id}'.format(rack_id='rack_id_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(rack_update),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
