DROP TABLE IF EXISTS racks_timeseries_configs;
DROP TABLE IF EXISTS racks;

CREATE TABLE racks (
    r_id                                INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    r_f_id                              INT UNSIGNED NOT NULL,
    r_total_available_power             DECIMAL(20, 9) DEFAULT 5,
    r_total_available_cooling_capacity  DECIMAL(20, 9) DEFAULT 5,
    r_number_of_pdus                    INT UNSIGNED DEFAULT 2,
    r_power_redundancy                  INT UNSIGNED DEFAULT 2,
    r_product_passport                  JSON DEFAULT NULL,
    r_prometheus_endpoint               VARCHAR(255) NOT NULL,
    r_created_at                        TIMESTAMP NOT NULL,
    r_updated_at                        TIMESTAMP NOT NULL,
    CONSTRAINT r_fk FOREIGN KEY fk (r_f_id) REFERENCES facilities (f_id) ON DELETE CASCADE
);

CREATE TABLE racks_timeseries_configs (
    rtc_id                              INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    rtc_r_id                            INT UNSIGNED NOT NULL,
    rtc_name                            VARCHAR(200) NOT NULL,
    rtc_unit                            VARCHAR(200) NOT NULL,
    rtc_granularity_seconds             INT NOT NULL,
    rtc_labels                          JSON,
    CONSTRAINT rtc_fk FOREIGN KEY fk (rtc_r_id) REFERENCES racks (r_id) ON DELETE CASCADE
);
