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
  Default: "192.168.110.128/25"
  Description: "VPC Private Subnet Cidr Block (/25)"

# Key pair name
Parameters.KeyPair =
  Type: "String"
  Description: "EC2 Instance Key Pair Name"

#-------------------------------------------------
# Mappings
#-------------------------------------------------

baseTag = [
  Key: "Name"
  Value: 
    Ref: "TagName"
]

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
    Tags: baseTag

Resources.InternetGateway =
  Type: "AWS::EC2::InternetGateway"
  Properties:
    Tags: baseTag

# connect VPC <=> InternetGateway
Resources.AttachGateway =
  Type: "AWS::EC2::VPCGatewayAttachment"
  Properties:
    VpcId:
      Ref: "VPC"
    InternetGatewayId:
      Ref: "InternetGateway"

Resources.DHCPOption =
  Type: "AWS::EC2::DHCPOptions"
  Properties:
    DomainName: "ap-northeast-1.compute.internal"
    DomainNameServers: ["AmazonProvidedDNS"]

Resources.DHCPOptionAssociation =
  Type: "AWS::EC2::VPCDHCPOptionsAssociation"
  Properties:
    VpcId:
      Ref: "VPC"
    DhcpOptionsId:
      Ref: "DHCPOption"

Resources.NetworkAcl =
  Type: "AWS::EC2::NetworkAcl"
  Properties:
    VpcId:
      Ref: "VPC"
    Tags: baseTag

Resources.NetworkAclEntry1 =
  Type: "AWS::EC2::NetworkAclEntry"
  Properties:
    CidrBlock: "0.0.0.0/0"
    Egress: "true"
    Protocol: "-1"
    RuleAction: "allow"
    RuleNumber: "100"
    NetworkAclId:
      Ref: "NetworkAcl"

Resources.NetworkAclEntry2 =
  Type: "AWS::EC2::NetworkAclEntry"
  Properties:
    CidrBlock: "0.0.0.0/0"
    Protocol: "-1"
    RuleAction: "allow"
    RuleNumber: "100"
    NetworkAclId:
      Ref: "NetworkAcl"

# Public Subnet --->
Resources.PublicSubnet =
  Type: "AWS::EC2::Subnet"
  Properties:
    VpcId:
      Ref: "VPC"
    CidrBlock:
      Ref: "VpcPublicCidrBlock"
    AvailabilityZone: "ap-northeast-1a"
    Tags: baseTag

Resources.PublicRouteTable =
  Type: "AWS::EC2::RouteTable"
  Properties:
    VpcId:
      Ref: "VPC"
    Tags: baseTag

Resources.PublicRoute1 =
  Type: "AWS::EC2::Route"
  Properties:
    DestinationCidrBlock: "0.0.0.0/0"
    RouteTableId:
      Ref: "PublicRouteTable"
    GatewayId:
      Ref: "InternetGateway"
  DependsOn: "AttachGateway"

# connect Subnet <=> RouteTable
Resources.PublicSubnetRouteTableAssociation =
  Type: "AWS::EC2::SubnetRouteTableAssociation"
  Properties:
    SubnetId:
      Ref: "PublicSubnet"
    RouteTableId:
      Ref: "PublicRouteTable"

Resources.PublicSubnetNetworkAcl =
  Type: "AWS::EC2::SubnetNetworkAclAssociation"
  Properties:
    NetworkAclId:
      Ref: "NetworkAcl"
    SubnetId:
      Ref: "PublicSubnet"

Resources.PublicSecurityGroup =
  Type: "AWS::EC2::SecurityGroup"
  Properties:
    GroupDescription: "VPC Public Subnet Security Group"
    VpcId:
      Ref: "VPC"
    Tags: baseTag

Resources.PublicSecurityGroupIngress =
  Type: "AWS::EC2::SecurityGroupIngress"
  Properties:
    GroupId:
      Ref: "PublicSecurityGroup"
    IpProtocol: "-1"
    SourceSecurityGroupId:
      Ref: "PublicSecurityGroup"

Resources.PulicSecurityGroupIngressSSH =
  Type: "AWS::EC2::SecurityGroupIngress"
  Properties:
    GroupId:
      Ref: "PublicSecurityGroup"
    IpProtocol: "tcp"
    FromPort: "22"
    ToPort: "22"
    CidrIp: "0.0.0.0/0"

Resources.PublicSecurityGroupIngressHTTP =
  Type: "AWS::EC2::SecurityGroupIngress"
  Properties:
    GroupId:
      Ref: "PublicSecurityGroup"
    IpProtocol: "tcp"
    FromPort: "80"
    ToPort: "80"
    CidrIp: "0.0.0.0/0"

Resources.PublicSecurityGroupIngressGroup =
  Type: "AWS::EC2::SecurityGroupIngress"
  Properties:
    GroupId:
      Ref: "PublicSecurityGroup"
    IpProtocol: "-1"
    SourceSecurityGroupId:
      Ref: "PublicSecurityGroup"

Resources.PublicSecurityGroupEgress =
  Type: "AWS::EC2::SecurityGroupEgress"
  Properties:
    GroupId:
      Ref: "PublicSecurityGroup"
    IpProtocol: "-1"
    CidrIp: "0.0.0.0/0"

# <--= Public Subnet

# Private Subnet --->
Resources.PrivateSubnet =
  Type: "AWS::EC2::Subnet"
  Properties:
    VpcId:
      Ref: "VPC"
    CidrBlock:
      Ref: "VpcPrivateCidrBlock"
    AvailabilityZone: "ap-northeast-1a"
    Tags: baseTag

Resources.PrivateRouteTable =
  Type: "AWS::EC2::RouteTable"
  Properties:
    VpcId:
      Ref: "VPC"
    Tags: baseTag

Resources.PrivateRoute1 =
  Type: "AWS::EC2::Route"
  Properties:
    DestinationCidrBlock: "0.0.0.0/0"
    RouteTableId:
      Ref: "PrivateRouteTable"
    InstanceId:
      Ref: "NATInstance"

# connect Subnet <=> RouteTable
Resources.PrivateRouteTableAssociation =
  Type: "AWS::EC2::SubnetRouteTableAssociation"
  Properties:
    SubnetId:
      Ref: "PrivateSubnet"
    RouteTableId:
      Ref: "PrivateRouteTable"

Resources.PrivateSubnetNetworkAcl =
  Type: "AWS::EC2::SubnetNetworkAclAssociation"
  Properties:
    NetworkAclId:
      Ref: "NetworkAcl"
    SubnetId:
      Ref: "PrivateSubnet"

Resources.PrivateSecurityGroup =
  Type:  "AWS::EC2::SecurityGroup"
  Properties:
    GroupDescription: "VPC Private Security Group"
    VpcId:
      Ref: "VPC"
    Tags: baseTag

Resources.PrivateSecurityGroupIngressGroup =
  Type:  "AWS::EC2::SecurityGroupIngress"
  Properties:
    GroupId:
      Ref: "PrivateSecurityGroup"
    IpProtocol: "-1"
    SourceSecurityGroupId:
      Ref: "PrivateSecurityGroup"

Resources.PrivateSecurityGroupEgress =
  Type: "AWS::EC2::SecurityGroupEgress"
  Properties:
    GroupId:
      Ref: "PrivateSecurityGroup"
    IpProtocol: "-1"
    CidrIp: "0.0.0.0/0"

# <--= Private Subnet

# NAT Instance
Resources.NATInstance =
  Type: "AWS::EC2::Instance"
  Properties:
    DisableApiTermination: "false"
    ImageId: "ami-03cf3903"
    InstanceInitiatedShutdownBehavior: "stop"
    InstanceType: "t2.micro"
    KeyName:
      Ref: "KeyPair"
    Monitoring: "false"
    NetworkInterfaces: [
      AssociatePublicIpAddress: "true"
      DeleteOnTermination: "true"
      Description: "Primary network interface"
      DeviceIndex: 0
      SubnetId:
        Ref: "PublicSubnet"
#      PrivateIpAddress: [
#        PrivateIpAddress: "192.168.110.10"
#        Primary: "true"
#      ]
      GroupSet: [
        {Ref: "PublicSecurityGroup"}
        {Ref: "PrivateSecurityGroup"}
      ]
    ]
    Tags: baseTag


#-------------------------------------------------
# Outputs
#-------------------------------------------------
Outputs.VpcId =
  Value:
    Ref: "VPC"
  Description: "VPC ID of newly created VPC"

Outputs.VpdCidr =
  Value:
    Ref: "VpcCidrBlock"
  Description: "VPC Cidr Block"

Outputs.PublicSubnetCidr =
  Value:
    Ref: "VpcPublicCidrBlock"
  Description: "VPC Public Subnet Cidr Block"

Outputs.PrivateSubnetCidr =
  Value:
    Ref: "VpcPrivateCidrBlock"
  Description: "VPC Private Subnet Cidr Block"

Outputs.NATInstanceIp =
  Value:
    Ref: "NATInstance"
  Description: "NAT Instance"

# EOF
