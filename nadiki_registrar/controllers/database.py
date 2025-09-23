from sqlalchemy import create_engine, MetaData, Table
from nadiki_registrar.controllers.config import DATABASE_URL

#
# Initialize SQLAlchemy
#
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
meta = MetaData()
meta.reflect(engine)
facilities                      = Table("facilities",                       meta, autoload_with=engine)
facilities_cooling_fluids       = Table("facilities_cooling_fluids",        meta, autoload_with=engine)
facilities_timeseries_configs   = Table("facilities_timeseries_configs",    meta, autoload_with=engine)
facilities_impact_assessment    = Table("facilities_impact_assessment",     meta, autoload_with=engine)
racks                           = Table("racks",                            meta, autoload_with=engine)
racks_timeseries_configs        = Table("racks_timeseries_configs",         meta, autoload_with=engine)
servers                         = Table("servers",                          meta, autoload_with=engine)
servers_timeseries_configs      = Table("servers_timeseries_configs",       meta, autoload_with=engine)
servers_cpus                    = Table("servers_cpus",                     meta, autoload_with=engine)
servers_gpus                    = Table("servers_gpus",                     meta, autoload_with=engine)
servers_fpgas                   = Table("servers_fpgas",                    meta, autoload_with=engine)
servers_storage_devices         = Table("servers_storage_devices",          meta, autoload_with=engine)
