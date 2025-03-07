from sqlalchemy import create_engine, MetaData, Table
from nadiki_registrar.controllers.config import DATABASE_URL

#
# Initialize SQLAlchemy
#
engine = create_engine(DATABASE_URL)
meta = MetaData()
meta.reflect(engine)
facilities = Table("facilities", meta, autoload_with=engine)
facilities_cooling_fluids = Table("facilities_cooling_fluids", meta, autoload_with=engine)
facilities_timeseries_configs = Table("facilities_timeseries_configs", meta, autoload_with=engine)
racks = Table("racks", meta, autoload_with=engine)
racks_timeseries_configs = Table("racks_timeseries_configs", meta, autoload_with=engine)
