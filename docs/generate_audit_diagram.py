#!/usr/bin/env python3
# pyright: reportMissingImports=false
"""Generate an audit-focused infrastructure diagram PNG.

Prerequisites on macOS:
  brew install graphviz
  python3 -m pip install diagrams

Run:
  python3 docs/generate_audit_diagram.py

Output:
  docs/poc-architecture-audit.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2AutoScaling, EC2Instance
from diagrams.aws.network import ALB
from diagrams.aws.security import CertificateManager
from diagrams.generic.network import Firewall
from diagrams.onprem.network import Internet
from diagrams.onprem.compute import Server


with Diagram(
    "POC Infrastructure (Audit View)",
    filename="docs/poc-architecture-audit",
    show=False,
    direction="LR",
):
    internet = Internet("Client IP Allowlist")
    secureweb = Server("secureweb.com")

    with Cluster("Control Plane"):
        acm = CertificateManager("TLS Certificate")

    with Cluster("Workload Plane"):
        alb = ALB("ALB\nIngress 443\n3 public subnets")
        app = EC2AutoScaling("App ASG\nDependency Gate\nCurrent: public-fallback")
        db = EC2Instance("MySQL EC2\nCurrent: public-fallback")
        fallback = Server("Reason:\ndefault VPC has no private subnets\nTerraform will use private subnets later if they are added")

    with Cluster("Security Controls"):
        sg_alb = Firewall("SG-ALB\nInbound finite CIDRs")
        sg_app = Firewall("SG-APP\nOnly from ALB")
        sg_db = Firewall("SG-DB\nOnly from APP")

    internet >> Edge(label="HTTPS 443") >> alb
    acm >> Edge(label="TLS attached") >> alb
    alb >> Edge(label="HTTP 80") >> app
    app >> Edge(label="MySQL 3306") >> db
    app >> Edge(label="Outbound HTTPS 443") >> secureweb

    sg_alb - alb
    sg_app - app
    sg_db - db
    fallback - app
    fallback - db
