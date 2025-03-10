DROP TABLE IF EXISTS servers_timeseries_configs;
DROP TABLE IF EXISTS servers_cpus;
DROP TABLE IF EXISTS servers_gpus;
DROP TABLE IF EXISTS servers_fpgas;
DROP TABLE IF EXISTS servers_hard_disks;
DROP TABLE IF EXISTS servers;

CREATE TABLE servers (
    s_id                        INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    s_r_id                      INT UNSIGNED NOT NULL,                    
    s_rated_power               DECIMAL(20,9),
    s_total_cpu_sockets         INT UNSIGNED DEFAULT 2,
    s_number_of_psus            INT UNSIGNED DEFAULT 2,
    s_total_installed_memory    INT UNSIGNED,
    s_number_of_memory_units    INT UNSIGNED,
    s_total_gpus                INT UNSIGNED DEFAULT 0,
    s_total_fpgas               INT UNSIGNED DEFAULT 0,
    s_product_passport          JSON,
    s_cooling_type              VARCHAR(50),
    s_created_at                TIMESTAMP NOT NULL,
    s_updated_at                TIMESTAMP NOT NULL,
    CONSTRAINT s_fk FOREIGN KEY fk (s_r_id) REFERENCES racks (r_id) ON DELETE CASCADE
);

CREATE TABLE servers_cpus (
    sc_s_id     INT UNSIGNED NOT NULL,
    sc_vendor   VARCHAR(255) NOT NULL,
    sc_type     VARCHAR(255) NOT NULL,
    CONSTRAINT sc_fk FOREIGN KEY fk (sc_s_id) REFERENCES servers (s_id) ON DELETE CASCADE
);

CREATE TABLE servers_gpus(
    sg_s_id     INT UNSIGNED NOT NULL,
    sg_vendor   VARCHAR(255) NOT NULL,
    sg_type     VARCHAR(255) NOT NULL,
    CONSTRAINT sg_fk FOREIGN KEY fk (sg_s_id) REFERENCES servers (s_id) ON DELETE CASCADE
);

CREATE TABLE servers_fpgas(
    sf_s_id     INT UNSIGNED NOT NULL,
    sf_vendor   VARCHAR(255) NOT NULL,
    sf_type     VARCHAR(255) NOT NULL,
    CONSTRAINT sf_fk FOREIGN KEY fk (sf_s_id) REFERENCES servers (s_id) ON DELETE CASCADE
);

CREATE TABLE servers_hard_disks(
    sh_s_id     INT UNSIGNED NOT NULL,
    sh_vendor   VARCHAR(255) NOT NULL,
    sh_type     VARCHAR(255) NOT NULL,
    CONSTRAINT sh_fk FOREIGN KEY fk (sh_s_id) REFERENCES servers (s_id) ON DELETE CASCADE
);
 
CREATE TABLE servers_timeseries_configs (
    stc_id                              INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    stc_s_id                            INT UNSIGNED NOT NULL,
    stc_name                            VARCHAR(200) NOT NULL,
    stc_unit                            VARCHAR(200) NOT NULL,
    stc_granularity_seconds             INT NOT NULL,
    stc_labels                          JSON,
    CONSTRAINT stc_fk FOREIGN KEY fk (stc_s_id) REFERENCES servers (s_id) ON DELETE CASCADE
);
