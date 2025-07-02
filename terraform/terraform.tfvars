namespace = "nadiki"
stage     = "prod"
name      = "registrar"
# "n" for nadiki is the 14th letter of the alphabet
# "l" for leitmotic is the 12th letter of the alphabet
# and yes, /24 should really be enough
vpc_cidr_block                  = "10.14.12.0/24"
availability_zones              = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
mariadb_image_tag               = "11.7.2"
registrar_image_tag             = "latest"
ui_image_tag                    = "latest"
jupyter_lab_image_tag           = "main"
telegraf_promrcv_image_tag      = "main"
influxdb_container_port         = 8443 # change this because we use TLS
ui_container_port               = 443
jupyter_lab_container_port      = 8443
telegraf_promrcv_container_port = 8443
influxdb_cpu                    = 4096
influxdb_ram                    = 16384
telegraf_promrcv_cpu            = 1024
telegraf_promrcv_ram            = 2048
timeplus_proton_cpu             = 1024
timeplus_proton_ram             = 2048
jupyter_lab_cpu                 = 4096
jupyter_lab_ram                 = 8192
siec_scraper_ami_id             = "ami-08aa372c213609089" # Amazon Linux 2023 AMI x86_64
siec_scraper_instance_type      = "t3.medium"
