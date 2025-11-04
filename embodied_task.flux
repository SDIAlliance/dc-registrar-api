import "influxdata/influxdb/secrets"
import "http"
import "http/requests"
import "experimental"
import jsonx "experimental/json"
import "json"
import "experimental/dynamic"
import "array"

option task = { 
  name: "AGGREGATE-EMBODIED-%%FACILITY%%",
  every: 15m,
}

facilityId = "%%FACILITY%%"

HOURS_PER_YEAR = 365*24

// this must be 60m/every for "every" being the value from the options block above
JOBS_PER_HOUR = 4

registrarUrl = secrets.get(key: "REGISTRAR_URL")

registrarUsername = secrets.get(key: "REGISTRAR_BASIC_AUTH_USERNAME")

registrarPassword = secrets.get(key: "REGISTRAR_BASIC_AUTH_PASSWORD")

processJsonResponse = (t=<-, measurementName) => {
    res = t |> array.map(fn: (x) => {
        ia = jsonx.parse(data: dynamic.jsonEncode(v: x.impactAssessment))
        return {ia with
            id: string(v: x["id"]),
            rack_id: if exists x.rack_id  then string(v: x.rack_id) else "",
            facility_id: if exists x.facility_id  then string(v: x.facility_id) else "",
            country_code: string(v: dynamic.asArray(v: x.timeSeriesConfig.dataPoints)[0].tags.country_code),
            lifetime: float(v: if exists x["expected_lifetime"] then x["expected_lifetime"] else x["lifetimeFacility"]), // names are different for servers and facilities
            "_time": now(),
        }
    })

    return array.from(rows: res)
    |> experimental.unpivot(otherColumns: ["id", "_time", "rack_id", "facility_id", "country_code", "lifetime"])
    |> map(fn: (r) => ({r with
        _value: float(v: r._value) / (float(v: HOURS_PER_YEAR)*r.lifetime*float(v: JOBS_PER_HOUR)),
        _time: time(v: r["_time"]),
        _measurement: measurementName
    }))
}

x = requests.get(
 url: registrarUrl+"/v1/servers?facility_id="+facilityId,
 headers: ["Authorization": http.basicAuth(u: registrarUsername, p: registrarPassword)]
)

j = dynamic.jsonParse(data: x.body)

// In case there are no servers, the code below would fail because array.from() requires at least one row
// in order to derive a schema. The recommended workaround seems to be to insert a dymmat record and filter
// it out later in the pipeline.
//
// I apologize to my future self for this mess!
withAssessment = array.filter(arr: dynamic.asArray(v: j.items) |> array.concat(v: dynamic.asArray(v: dynamic.jsonParse(data: json.encode(v: [{
        "impactAssessment":     {"climate_change": 0},
        "expected_lifetime":    0,
        "lifetimeFacility":     0,
        "timeSeriesConfig":     {"dataPoints": [{"tags": {"country_code": "dummy"}}]},
        "facility_id":          "dummy",
        "rack_id":              "dummy",
        "id":                   "dummy"
        }])))), fn: (x) => exists x.impactAssessment.climate_change)

withAssessment
|> processJsonResponse(measurementName: "server_embodied")
|> filter(fn: (r) => r.id != "dummy")
|> to(bucket: "NADIKI-AGGREGATION")

y = requests.get(
 url: registrarUrl+"/v1/facilities/"+facilityId,
 headers: ["Authorization": http.basicAuth(u: registrarUsername, p: registrarPassword)]
)

k = dynamic.jsonParse(data: y.body)

array.filter(arr: [k], fn: (x) => exists x.impactAssessment)
|> processJsonResponse(measurementName: "facility_embodied")
|> drop(columns: ["facility_id", "rack_id"])
|> to(bucket: "NADIKI-AGGREGATION")
