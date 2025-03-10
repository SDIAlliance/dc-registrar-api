#
# classes to encapsulate the information encoded into facility-, rack- and server-id
#
#

import re

class BaseId:

    @property
    def number(self):
        return self._number

    @number.setter
    def number(self, n):
        self._number = n

class FacilityId(BaseId):

    pattern = re.compile("FACILITY-([A-Z]{3})-([0-9]{3,})")

    @staticmethod
    def fromString(str):
        groups = FacilityId.pattern.match(str)
        if groups != None:
            return FacilityId(groups[1], int(groups[2]))
        else:
            return None
    
    def __init__(self, country_code, number):
        self.country_code = country_code
        self.number = number

    @property
    def country_code(self):
        return self._country_code

    @country_code.setter
    def country_code(self, cc):
        self._country_code = cc

    def toString(self):
        return f"FACILITY-{self.country_code}-{'%03i' % self.number}"

class RackId(BaseId):

    pattern = re.compile("RACK-(FACILITY-[A-Z]{3}-[0-9]{3,})-([0-9]{3,})")

    @staticmethod
    def fromString(str):
        groups = RackId.pattern.match(str)
        if groups != None:
            return RackId(groups[1], int(groups[2]))

    def __init__(self, facility_id, number):
        self.facility = FacilityId.fromString(facility_id)
        self.number = number

    @property
    def facility(self):
        return self._facility
    
    @facility.setter
    def facility(self, f):
        self._facility = f

    def toString(self):
        return f"RACK-{self.facility.toString()}-{'%03i' % self.number}"

class ServerId(BaseId):

    pattern = re.compile("SERVER-(RACK-FACILITY-[A-Z]{3}-[0-9]{3,}-[0-9]{3,})-([0-9]{3,})")

    @staticmethod
    def fromString(str):
        groups = ServerId.pattern.match(str)
        if groups != None:
            return ServerId(groups[1], int(groups[2]))

    def __init__(self, rack_id, number):
        self.rack = RackId.fromString(rack_id)
        self.number = number

    @property
    def rack(self):
        return self._rack

    @rack.setter
    def rack(self, r):
        self._rack = r

    def toString(self):
        return f"SERVER-{self.rack.toString()}-{'%03i' % self.number}"
