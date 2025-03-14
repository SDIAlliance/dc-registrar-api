namespace = "nadiki"
stage     = "prod"
name      = "registrar"
# "n" for nadiki is the 14th letter of the alphabet
# "l" for leitmotic is the 12th letter of the alphabet
# and yes, /24 should really be enough
vpc_cidr_block     = "10.14.12.0/24"
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
mariadb_image_tag  = "11.7.2"
