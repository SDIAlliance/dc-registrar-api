import "interpolate"
import "array"
option task = { 
  name: "AGGREGATE-OPERATIONAL-%%FACILITY%%",
  every: 4h,
}

input_bucket = "%%FACILITY%%"

output_bucket = "NADIKI-AGGREGATION"

window_size = 15m

_watts_to_kwh = (watts, ws) => watts * 0.001*float(v: int(v: window_size))/float(v: int(v: 60m))

_renewable_energy_use_kwh = (r, ws) => (
   _watts_to_kwh(watts: r.grid_transformers_avg_watts, ws: ws)
   * r["grid_renewable_percentage"]/100.0
   )

_non_renewable_energy_use = (r, ws) => (
  (_watts_to_kwh(watts: r.grid_transformers_avg_watts, ws: window_size) - _renewable_energy_use_kwh(r: r, ws: window_size))
)

_renewable_energy_use_incl_onsite_kwh = (r, ws) => (
  (_renewable_energy_use_kwh(r: r, ws: window_size) + _watts_to_kwh(watts: r.onsite_renewable_energy_avg_watts, ws: window_size))
)

_non_renewable_energy_use_incl_generators_kwh = (r, ws) => (
  (_non_renewable_energy_use(r: r, ws: window_size) + _watts_to_kwh(watts: r.total_generator_avg_watts, ws: window_size))
)

data = from(bucket: input_bucket)
|> range(start: -12h)
|> filter(fn: (r) => r["_measurement"] == "facility")
|> interpolate.linear(every: window_size)
|> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
|> filter(fn: (r) => exists r.grid_transformers_avg_watts and exists r.grid_renewable_percentage and exists r.onsite_renewable_energy_avg_watts and exists r.total_generator_avg_watts and exists r.grid_emission_factor_grams)

data
|> map(fn: (r) => ({r with
_measurement: "renewable_energy_use_kwh",
_value: (_renewable_energy_use_kwh(r: r, ws: window_size)),
_field: "_value"
}))
|> drop(columns: ["rack_id", "server_id"])
|> to(bucket: output_bucket)

data
|> map(fn: (r) => ({r with
_measurement: "non_renewable_energy_use_kwh",
_value: _non_renewable_energy_use(r: r, ws: window_size),
_field: "_value"
}))
|> filter(fn: (r) => exists r._value)
|> drop(columns: ["rack_id", "server_id"])
|> to(bucket: output_bucket)

data
|> map(fn: (r) => ({r with
_measurement: "renewable_energy_use_incl_onsite_kwh",
_value: _renewable_energy_use_incl_onsite_kwh(r: r, ws: window_size),
_field: "_value"
}))
|> filter(fn: (r) => exists r._value)
|> drop(columns: ["rack_id", "server_id"])
|> to(bucket: output_bucket)

data
|> map(fn: (r) => ({r with
_measurement: "non_renewable_energy_use_incl_generators_kwh",
_value: _non_renewable_energy_use_incl_generators_kwh(r: r, ws: window_size),
_field: "_value"
}))
|> filter(fn: (r) => exists r._value)
|> drop(columns: ["rack_id", "server_id"])
|> to(bucket: output_bucket)

data
|> map(fn: (r) => ({r with
_measurement: "operational_co2_emissions",
_value: _watts_to_kwh(watts: r.grid_transformers_avg_watts, ws: window_size) * r.grid_emission_factor_grams,
_field: "_value"
}))
|> filter(fn: (r) => exists r._value)
|> drop(columns: ["rack_id", "server_id"])
|> to(bucket: output_bucket)