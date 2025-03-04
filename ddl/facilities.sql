-- Although OpenAPI generator can generate SQL schemas, I wrote this one by
-- hand. The generated code would store geo location as TEXT and the array
-- of cooling fluids as JSON. Furthermore, it does not contain an ID.
-- Also it would use camel-cased field names, which is unusual in SQL.
-- Maybe all of this could be tweaked in the schema and in the generator,
-- but for now, I'll go with the manual approach.
DROP TABLE IF EXISTS facilities;
CREATE TABLE facilities (
    id                              VARCHAR(36) NOT NULL PRIMARY KEY,
    geo_lon                         DECIMAL(6,5) NOT NULL,
    geo_lat                         DECIMAL(6,5) NOT NULL,
    embedded_ghg_emissions_facility DECIMAL(20,9),
    lifetime_facility               INTEGER UNSIGNED,
    embedded_ghg_emissions_assets   DECIMAL(20,9),
    lifetime_assets                 INTEGER UNSIGNED,
    maintenance_hours_generator     DECIMAL(20, 9) DEFAULT NULL,
    installed_capacity              DECIMAL(20, 9) DEFAULT NULL,
    grid_power_feeds                INT UNSIGNED DEFAULT 3,
    design_pue                      DECIMAL(20, 9) UNSIGNED DEFAULT '1.4',
    tier_level                      ENUM('1', '2', '3', '4') DEFAULT '3',
    white_space_floors              INT UNSIGNED DEFAULT 1,
    total_space                     DECIMAL(20, 9) DEFAULT NULL,
    white_space                     DECIMAL(20, 9) DEFAULT NULL,
    UNIQUE (geo_lat, geo_lon)
);

DROP TABLE IF EXISTS facilities_cooling_fluids;
CREATE TABLE facilities_cooling_fluids (
    id                              INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    facility_id                     VARCHAR(36) NOT NULL,
    cf_type                         TEXT NOT NULL,
    amount                          DECIMAL(20, 9) NOT NULL,
    gwp_factor                      DECIMAL(20, 9) DEFAULT NULL,
    CONSTRAINT fk FOREIGN KEY fk (facility_id) REFERENCES facilities (id) ON DELETE CASCADE
);
