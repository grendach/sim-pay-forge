# POC Infrastructure Diagram

Current deployment note: this AWS account's default VPC has no private subnets, so the workload placement is currently `public-fallback`. ALB still uses 3 selected public subnets, and app/DB also run in selected public subnets until private subnets exist.

```mermaid
graph TD
  internet[Internet Clients]
  secureweb[secureweb.com HTTPS]

  subgraph aws[AWS Account]
    subgraph vpc[Default VPC]
      subgraph s1[Public Subnet A]
        alb[ALB HTTPS 443]
      end

      subgraph s2[Public Subnet B - current workload placement]
        app1[App EC2 in ASG]
      end

      subgraph s3[Public Subnet C - current workload placement]
        app2[App EC2 in ASG]
      end

      subgraph s4[Selected Public Subnet - current workload placement]
        db[MySQL EC2]
      end

      fallback[Preferred behavior: if private subnets are added to the default VPC later, app/db move there]

      sgAlb[SG ALB inbound finite IP list]
      sgApp[SG App inbound from ALB]
      sgDb[SG DB inbound from App]
    end

    acm[ACM Certificate]
  end

  internet -->|HTTPS| alb
  acm --> alb
  alb -->|HTTP 80| app1
  alb -->|HTTP 80| app2
  app1 -->|MySQL 3306| db
  app2 -->|MySQL 3306| db
  app1 -->|HTTPS 443| secureweb
  app2 -->|HTTPS 443| secureweb

  sgAlb --- alb
  sgApp --- app1
  sgApp --- app2
  sgDb --- db
  fallback -.applies to.-> app1
  fallback -.applies to.-> db
```
