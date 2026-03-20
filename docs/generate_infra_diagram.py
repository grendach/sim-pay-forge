#!/usr/bin/env python3
# pyright: reportMissingImports=false
"""Generate infrastructure diagram PNG for sim-pay-forge POC.

Prerequisites on macOS:
  brew install graphviz
  python3 -m pip install diagrams

Run:
  python3 docs/generate_infra_diagram.py

Output:
  docs/poc-architecture-python.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2AutoScaling, EC2Instance
from diagrams.aws.network import ALB, InternetGateway, VPC
from diagrams.aws.security import CertificateManager
from diagrams.generic.network import Firewall
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Internet


with Diagram(
    "POC Infrastructure (Python)",
    filename="docs/poc-architecture-python",
    show=False,
    direction="TB",
):
    internet = Internet("Internet Clients")
    secureweb = Server("secureweb.com")
    acm = CertificateManager("ACM Cert")

    with Cluster("AWS Account"):
        igw = InternetGateway("Internet GW")

        with Cluster("Default VPC"):
            vpc = VPC("Default VPC")

            with Cluster("Public Subnet A (ALB)"):
                alb = ALB("Public ALB\nHTTPS 443")

            with Cluster("Public Subnet B (current app placement)"):
                app_asg = EC2AutoScaling("App ASG\nEC2 Linux\npublic-fallback active")

            with Cluster("Public Subnet C (current db placement)"):
                db = EC2Instance("MySQL EC2\npublic-fallback active")

            fallback = Server("Current state:\nno private subnets in default VPC\napp/db use public subnets\nIf private subnets are added later, workloads move there")

            sg_alb = Firewall("SG ALB\nfinite inbound CIDRs")
            sg_app = Firewall("SG App\nallow from ALB")
            sg_db = Firewall("SG DB\nallow from App")

    internet >> Edge(label="HTTPS") >> alb
    acm >> alb
    alb >> Edge(label="HTTP 80") >> app_asg
    app_asg >> Edge(label="MySQL 3306") >> db
    app_asg >> Edge(label="HTTPS 443") >> secureweb

    sg_alb - alb
    sg_app - app_asg
    sg_db - db
    fallback - app_asg
    fallback - db

    igw - vpc
