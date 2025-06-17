# AWS Static Website with S3 + CloudFront

A production-ready static website template with AWS infrastructure as code, featuring S3 hosting, CloudFront CDN, SSL certificates, and automated deployment scripts.

## 🏗️ Architecture Overview

This project implements a modern static website hosting solution on AWS with the following components:

### AWS Services Used

- **Amazon S3:** Static website hosting and storage
- **Amazon CloudFront:** Global CDN for fast content delivery
- **AWS Certificate Manager (ACM):** SSL/TLS certificates for HTTPS
- **Amazon Route 53:** DNS management and domain routing
- **AWS WAF:** Web Application Firewall for security
- **Amazon CloudWatch:** Monitoring and alerting

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:

- AWS CLI installed and configured
- Docker installed (for local development)
- `jq` installed (for JSON parsing)
- An AWS account with appropriate permissions
- A registered domain name (optional, for custom domain)

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd aws-static-website
```

### 2. Configure AWS Credentials

```bash
aws configure
Enter your AWS Access Key ID, Secret Access Key, and default region
```

### 3. Deploy Infrastructure

```bash
aws cloudformation deploy \
  --template-file aws/template.yaml \
  --stack-name my-static-website \
  --parameter-overrides \
    DomainName=yourdomain.com \
    SubdomainName=www \
    HostedZoneId=Z1234567890ABC \
    Environment=prod \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

### 4. Deploy Website Files

```bash
chmod +x aws/deploy.sh
./aws/deploy.sh --stack-name my-static-website
```

## 🛠️ Local Development

### Using Docker

```bash
docker build --target development -t my-static-website:dev .
docker run -p 8080:80 -v $(pwd)/src:/usr/share/nginx/html my-static-website:dev
```

Access your site at [http://localhost:8080](http://localhost:8080).

### Using Docker Compose (Optional)

Create a `docker-compose.yml`:

```yaml
version: '3.8'
services:
  website:
    build:
      context: .
      target: development
    ports:
      - "8080:80"
    volumes:
      - ./src:/usr/share/nginx/html
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
```

Then run:

```bash
docker-compose up -d
```

## 📋 Deployment Guide

### Manual Deployment

1️⃣ Deploy Infrastructure first:

```bash
aws cloudformation deploy \
  --template-file aws/template.yaml \
  --stack-name your-stack-name \
  --parameter-overrides \
    DomainName=yourdomain.com \
    SubdomainName=www \
    HostedZoneId=YOUR_HOSTED_ZONE_ID \
    Environment=prod
```

2️⃣ Deploy Website files:

```bash
./aws/deploy.sh --stack-name your-stack-name
```

### Deployment Script Options

```bash
./aws/deploy.sh --stack-name my-website
./aws/deploy.sh --stack-name my-website --environment staging --profile my-profile
./aws/deploy.sh --stack-name my-website --dry-run
./aws/deploy.sh --stack-name my-website --verbose
```

| Parameter | Description | Default |
|------------|------------|---------|
| `--stack-name` | CloudFormation stack name | **Required** |
| `--environment` | Environment (dev/staging/prod) | `prod` |
| `--profile` | AWS CLI profile | Default profile |
| `--region` | AWS region | `us-east-1` |
| `--dry-run` | Shows what would be deployed | `false` |
| `--verbose` | Enables verbose output | `false` |  

## 🔧 Configuration

### CloudFormation Parameter Overrides:

| Parameter | Description | Example |
|---------|---------|---------|
| `DomainName` | Your domain name | `example.com` |
| `SubdomainName` | Subdomain for the website | `www` |
| `HostedZoneId` | Route53 hosted zone ID | `Z1234567890ABC` |
| `Environment` | Environment name | `prod` |  

### Environment Variables:

Create `.env`:

```bash
AWS_PROFILE=your-profile
AWS_REGION=us-east-1
STACK_NAME=my-static-website
DOMAIN_NAME=yourdomain.com
```

## 🔒 Security Features

- AWS WAF Protection (common attack patterns, rate limiting, blocklist).
- CloudFront Security Headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Strict-Transport-Security, Content-Security-Policy).
- S3 (public block, encryption at rest, versioning, logging).

## 📊 Monitoring and Logging

### CloudWatch Alarms:

- CloudFront error rate
- Automatic notifications for high error rates

### Access Logs:

- CloudFront and S3 Access Logs for Audit

### Dashboard:

- CloudWatch Dashboard for:
  - Request count
  - Error rates
  - Cache hit ratio
  - Origin response times
  - WAF blocked requests

## 🚀 CI/CD Integration

### GitHub Actions Example:

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to S3 and CloudFront
        run: |
          chmod +x aws/deploy.sh
          ./aws/deploy.sh --stack-name ${{ secrets.STACK_NAME }}
```

## 🧪 Testing

### Local Testing:

```bash
docker build --target production -t my-static-website:prod .
docker run -p 8080:8080 my-static-website:prod
```

### Deployment Script (Dry Run)

```bash
./aws/deploy.sh --stack-name test-stack --dry-run
```

### Loading:

```bash
ab -n 1000 -c 10 https://yourdomain.com/
```

```bash
npm install -g artillery
artillery quick --count 10 --num 100 https://yourdomain.com/
```

## 🔧 Troubleshooting

| Issue | Solution |
|---------|---------|
| Certificate Validation Fails | Validate DNS and ACM in us-east-1 |
| CloudFront Distribution Fails | Check Origin Access and S3 policy |
| Deployment Script Fails | Validate AWS credentials, `jq` installation, stack, and permissions |
| AWS CLI `aws s3 sync` Fails | Check AWS CLI config, permissions, and policy |  

### Debugging:

```bash
aws sts get-caller-identity
aws cloudformation describe-stacks --stack-name your-stack-name
aws s3 sync src/ s3://your-bucket-name --dryrun
aws cloudfront get-distribution --id YOUR_ID
```

## 💰 Cost Optimization

### Estimated Monthly Costs:

|          | Cost |
|---------|---------|
| S3 | $1-5 |
| CloudFront | $1-10 |
| Route53 | $0.50 |
| ACM | Free |
| WAF | $1-5 |  

### Tips:

- CloudFront price class optimization
- S3 lifecycle policies
- Billing alerts
- S3 Intelligent Tiering for large sites

## 🤝 Contributing

1️⃣ Fork the repository  
2️⃣ Create a feature branch  
3️⃣ Make your changes  
4️⃣ Test thoroughly  
5️⃣ Submit a pull request  

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

## 🆘 Support

If you encounter issues:

- Check this README first
- Review AWS CloudFormation events
- Check CloudWatch logs
- Open an Issue in this repository

## 🔗 Useful Links

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html)  
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)  
- [AWS CLI Reference](https://awscli.amazonaws.com/)  
- [CloudFormation Template Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html)  

---

🚀 Happy Deploying!  
