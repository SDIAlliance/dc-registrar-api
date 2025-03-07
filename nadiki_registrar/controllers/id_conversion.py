import re

def facility_numeric_to_human_readable_id(id, country_code):
    return f"FACILITY-{country_code}-{'%03i' % id}"

def facility_human_readable_to_numeric_id(id):
    r = re.compile("FACILITY-([A-Z]{3})-([0-9]{3})")
    m = r.match(id)
    return m.groups()

def rack_numeric_to_human_readable_id(id, facility_id):
    return f"RACK-{facility_id}-{'%03i' % id}"

def rack_human_readable_to_numeric_id(id):
    r = re.compile("RACK-(FACILITY-[A-Z]{3}-[0-9]{3})-([0-9]{3})")
    m = r.match(id)
    return m.groups()
