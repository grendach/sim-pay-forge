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
from diagrams.aws.network import ALB
from diagrams.aws.security import CertificateManager
from diagrams.generic.network import Firewall
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Internet


with Diagram(
    "sim-pay-forge (dev) — eu-central-1",
    filename="docs/poc-architecture-python",
    show=False,
    direction="TB",
):
    internet = Internet("Internet\n0.0.0.0/0")
    secureweb = Server("secureweb.com\nHTTPS startup check")

    with Cluster("Cloudflare — grendach.dev"):
        cf_dns = Server("altm-dev.grendach.dev\nCNAME → ALB DNS (manual)")

    with Cluster("AWS — eu-central-1"):
        acm = CertificateManager("ACM\naltm-dev.grendach.dev\n*.altm-dev.grendach.dev")

        with Cluster("Default VPC — 3 selected public subnets"):

            with Cluster("ALB layer"):
                alb = ALB("sim-pay-forge-dev-alb\nHTTPS 443 / HTTP 80")
                sg_alb = Firewall("sim-pay-forge-dev-alb-sg\nIN  TCP 80,443 ← 0.0.0.0/0\nOUT ALL  → 0.0.0.0/0")

            with Cluster("App layer  (public subnet — no private subnets in VPC)"):
                app_asg = EC2AutoScaling("sim-pay-forge-dev-app-asg\nt3.micro | AL2023 | nginx\ndocker-ce installed on boot")
                sg_app = Firewall("sim-pay-forge-dev-app-sg\nIN  TCP 80   ← ALB SG only\nOUT TCP 443 → 0.0.0.0/0")

            with Cluster("DB layer  (public subnet — no private subnets in VPC)"):
                db = EC2Instance("sim-pay-forge-dev-db\nt3.micro | AL2023 | MySQL 8")
                sg_db = Firewall("sim-pay-forge-dev-db-sg\nIN  TCP 3306 ← App SG only\nOUT TCP 443 → 0.0.0.0/0")

    internet >> Edge(label="HTTPS 443") >> alb
    cf_dns >> Edge(label="CNAME") >> alb
    acm >> Edge(label="TLS attached") >> alb
    alb >> Edge(label="HTTP 80") >> app_asg
    app_asg >> Edge(label="MySQL 3306") >> db
    app_asg >> Edge(label="HTTPS 443") >> secureweb

    sg_alb - alb
    sg_app - app_asg
    sg_db - db
