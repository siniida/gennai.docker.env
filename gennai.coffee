Description = "gennai@docker on AWS"

#-------------------------------------------------
# Paramaters
#-------------------------------------------------

# Name Tag 
Parameters.TagName =
  Type: "String"
  Default: "gennai@cloud"
  Description: "Name Tag Value"

# VPC Network
Parameters.VpcCidrBlock =
  Type: "String"
  Default: "192.168.110.0/24"
  Description: "VPC Cidr Block (/24)"

# VPC Public Network
Parameters.VpcPublicCidrBlock =
  Type: "String"
  Default: "192.168.110.0/25"
  Description: "VPC Public Subnet Cidr Block (/25)"

# VPC Private Network
Parameters.VpcPrivateCidrBlock =
  Type: "String"
  Default: "192.168.110.28/25"
  Description: "VPC Private Subnet Cidr Block (/25)"

#-------------------------------------------------
# Mappings
#-------------------------------------------------

#-------------------------------------------------
# Resources
#-------------------------------------------------

Resources.VPC =
  Type: "AWS::EC2::VPC"
  Properties:
    CidrBlock:
      Ref: "VpcCidrBlock"
    InstanceTenancy: "default"
    EnableDnsSupport: "true"
    EnableDnsHostnames: "false"
    Tags: [
      {
        Key: "Name"
        Value:
          Ref: "TagName"
      }
    ]
