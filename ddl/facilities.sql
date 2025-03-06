-- Although OpenAPI generator can generate SQL schemas, I wrote this one by
-- hand. The generated code would store geo location as TEXT and the array
-- of cooling fluids as JSON. Furthermore, it does not contain an ID.
-- Also it would use camel-cased field names, which is unusual in SQL.
-- Maybe all of this could be tweaked in the schema and in the generator,
-- but for now, I'll go with the manual approach.
DROP TABLE IF EXISTS facilities_cooling_fluids;
DROP TABLE IF EXISTS facilities_timeseries_configs;
DROP TABLE IF EXISTS facilities;
CREATE TABLE facilities (
    f_id                                VARCHAR(36) NOT NULL PRIMARY KEY,
    f_geo_lon                           DECIMAL(8,5) NOT NULL,
    f_geo_lat                           DECIMAL(8,5) NOT NULL,
    f_embedded_ghg_emissions_facility   DECIMAL(20,9),
    f_lifetime_facility                 INTEGER UNSIGNED,
    f_embedded_ghg_emissions_assets     DECIMAL(20,9),
    f_lifetime_assets                   INTEGER UNSIGNED,
    f_maintenance_hours_generator       DECIMAL(20, 9) DEFAULT NULL,
    f_installed_capacity                DECIMAL(20, 9) DEFAULT NULL,
    f_grid_power_feeds                  INT UNSIGNED DEFAULT 3,
    f_design_pue                        DECIMAL(20, 9) UNSIGNED DEFAULT '1.4',
    f_tier_level                        ENUM('1', '2', '3', '4') DEFAULT '3',
    f_white_space_floors                INT UNSIGNED DEFAULT 1,
    f_total_space                       DECIMAL(20, 9) DEFAULT NULL,
    f_white_space                       DECIMAL(20, 9) DEFAULT NULL,
    f_country_code                      VARCHAR(3) NOT NULL,
    f_prometheus_endpoint               VARCHAR(255) NOT NULL,
    f_created_at                        TIMESTAMP NOT NULL,
    f_updated_at                        TIMESTAMP NOT NULL,
    UNIQUE (f_geo_lat, f_geo_lon)
);

CREATE TABLE facilities_cooling_fluids (
    fcf_id                              INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    fcf_f_id                            VARCHAR(36) NOT NULL,
    fcf_type                            TEXT NOT NULL,
    fcf_amount                          DECIMAL(20, 9) NOT NULL,
    fcf_gwp_factor                      DECIMAL(20, 9) DEFAULT NULL,
    CONSTRAINT fcf_fk FOREIGN KEY fk (fcf_f_id) REFERENCES facilities (f_id) ON DELETE CASCADE
);

-- actually this is the structure of DataPoints in the spec ... rename this?
CREATE TABLE facilities_timeseries_configs (
    ftc_id                              INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    ftc_f_id                            VARCHAR(36) NOT NULL,
    ftc_name                            VARCHAR(200) NOT NULL,
    ftc_unit                            VARCHAR(200) NOT NULL,
    ftc_granularity_seconds             INT NOT NULL,
    ftc_labels                          JSON,
    CONSTRAINT ftc_fk FOREIGN KEY fk (ftc_f_id) REFERENCES facilities (f_id) ON DELETE CASCADE
);
