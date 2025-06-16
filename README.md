# AWS Static Website with S3 + CloudFront

A production-ready static website template with AWS infrastructure as code, featuring S3 hosting, CloudFront CDN, SSL certificates, and automated deployment scripts.

## 🏗️ Architecture Overview

This project implements a modern static website hosting solution on AWS with the following components:

### AWS Services Used

- **Amazon S3**: Static website hosting and storage
- **Amazon CloudFront**: Global CDN for fast content delivery
- **AWS Certificate Manager (ACM)**: SSL/TLS certificates for HTTPS
- **Amazon Route 53**: DNS management and domain routing
- **AWS WAF**: Web Application Firewall for security
- **Amazon CloudWatch**: Monitoring and alerting

### Architecture Diagram

\`\`\`
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Route 53  │───▶│  CloudFront  │───▶│     S3      │
│    (DNS)    │    │    (CDN)     │    │  (Storage)  │
└─────────────┘    └──────────────┘    └─────────────┘
                           │
                           ▼
                   ┌──────────────┐
                   │   AWS WAF    │
                   │ (Security)   │
                   └──────────────┘
\`\`\`

## 📁 Project Structure

\`\`\`
aws-static-website/
├── src/                          # Website source files
│   ├── index.html               # Main HTML file
│   ├── style.css                # Stylesheet
│   └── script.js                # JavaScript functionality
├── aws/                         # AWS infrastructure and deployment
│   ├── template.yaml            # CloudFormation template
│   └── deploy.sh                # Deployment script
├── Dockerfile                   # Docker configuration for local development
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
\`\`\`

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Docker](https://www.docker.com/) installed (for local development)
- [jq](https://stedolan.github.io/jq/) installed (for JSON parsing)
- An AWS account with appropriate permissions
- A registered domain name (optional, for custom domain)

### 1. Clone and Setup

\`\`\`bash
git clone <your-repo-url>
cd aws-static-website
\`\`\`

### 2. Configure AWS Credentials

\`\`\`bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and default region
\`\`\`

### 3. Deploy Infrastructure

\`\`\`bash
# Deploy the CloudFormation stack
aws cloudformation deploy \\
  --template-file aws/template.yaml \\
  --stack-name my-static-website \\
  --parameter-overrides \\
    DomainName=yourdomain.com \\
    SubdomainName=www \\
    HostedZoneId=Z1234567890ABC \\
    Environment=prod \\
  --capabilities CAPABILITY_IAM \\
  --region us-east-1
\`\`\`

### 4. Deploy Website Files

\`\`\`bash
# Make the deployment script executable
chmod +x aws/deploy.sh

# Deploy your website
./aws/deploy.sh --stack-name my-static-website
\`\`\`

## 🛠️ Local Development

### Using Docker

\`\`\`bash
# Build and run the development container
docker build --target development -t my-static-website:dev .
docker run -p 8080:80 -v \$(pwd)/src:/usr/share/nginx/html my-static-website:dev

# Access your site at http://localhost:8080
\`\`\`

### Using Docker Compose (Optional)

Create a \`docker-compose.yml\` file:

\`\`\`yaml
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
\`\`\`

Then run:

\`\`\`bash
docker-compose up -d
\`\`\`

## 📋 Deployment Guide

### Manual Deployment

1. **Deploy Infrastructure First**:
   \`\`\`bash
   aws cloudformation deploy \\
     --template-file aws/template.yaml \\
     --stack-name your-stack-name \\
     --parameter-overrides \\
       DomainName=yourdomain.com \\
       SubdomainName=www \\
       HostedZoneId=YOUR_HOSTED_ZONE_ID \\
       Environment=prod
   \`\`\`

2. **Deploy Website Files**:
   \`\`\`bash
   ./aws/deploy.sh --stack-name your-stack-name
   \`\`\`

### Deployment Script Options

The \`deploy.sh\` script supports various options:

\`\`\`bash
# Basic deployment
./aws/deploy.sh --stack-name my-website

# With custom environment and profile
./aws/deploy.sh --stack-name my-website --environment staging --profile my-profile

# Dry run to see what would be deployed
./aws/deploy.sh --stack-name my-website --dry-run

# Verbose output for debugging
./aws/deploy.sh --stack-name my-website --verbose
\`\`\`

### Script Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| \`--stack-name\` | CloudFormation stack name | Required |
| \`--environment\` | Environment (dev/staging/prod) | prod |
| \`--profile\` | AWS CLI profile | Default profile |
| \`--region\` | AWS region | us-east-1 |
| \`--dry-run\` | Show commands without executing | false |
| \`--verbose\` | Enable verbose output | false |

## 🔧 Configuration

### CloudFormation Parameters

Update these parameters in the CloudFormation template or pass them during deployment:

| Parameter | Description | Example |
|-----------|-------------|---------|
| \`DomainName\` | Your domain name | example.com |
| \`SubdomainName\` | Subdomain for the website | www |
| \`HostedZoneId\` | Route53 hosted zone ID | Z1234567890ABC |
| \`Environment\` | Environment name | prod |

### Environment Variables

For local development, you can create a \`.env\` file:

\`\`\`bash
AWS_PROFILE=your-profile
AWS_REGION=us-east-1
STACK_NAME=my-static-website
DOMAIN_NAME=yourdomain.com
\`\`\`

## 🔒 Security Features

This template includes several security best practices:

### AWS WAF Protection
- Common attack patterns blocked
- Known bad inputs filtered
- Rate limiting capabilities

### CloudFront Security Headers
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security
- Content-Security-Policy

### S3 Security
- Public access blocked
- Encryption at rest
- Versioning enabled
- Access logging

## 📊 Monitoring and Logging

### CloudWatch Alarms
- CloudFront error rate monitoring
- Automatic notifications for high error rates

### Access Logs
- CloudFront access logs stored in S3
- S3 access logs for audit trail

### Monitoring Dashboard

You can create a CloudWatch dashboard to monitor:
- Request count and error rates
- Cache hit ratio
- Origin response times
- WAF blocked requests

## 🚀 CI/CD Integration

### GitHub Actions Example

Create \`.github/workflows/deploy.yml\`:

\`\`\`yaml
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
        aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Deploy to S3 and CloudFront
      run: |
        chmod +x aws/deploy.sh
        ./aws/deploy.sh --stack-name \${{ secrets.STACK_NAME }}
\`\`\`

## 🧪 Testing

### Local Testing

\`\`\`bash
# Test with Docker
docker build --target production -t my-static-website:prod .
docker run -p 8080:8080 my-static-website:prod

# Test deployment script (dry run)
./aws/deploy.sh --stack-name test-stack --dry-run
\`\`\`

### Load Testing

Use tools like Apache Bench or Artillery to test performance:

\`\`\`bash
# Simple load test
ab -n 1000 -c 10 https://yourdomain.com/

# Or with Artillery
npm install -g artillery
artillery quick --count 10 --num 100 https://yourdomain.com/
\`\`\`

## 🔧 Troubleshooting

### Common Issues

1. **Certificate Validation Fails**
   - Ensure DNS records are properly configured
   - Certificate must be in us-east-1 region for CloudFront

2. **CloudFront Distribution Not Working**
   - Check Origin Access Control settings
   - Verify S3 bucket policy allows CloudFront access

3. **Deployment Script Fails**
   - Verify AWS credentials and permissions
   - Check if jq is installed
   - Ensure CloudFormation stack exists

### Debug Commands

\`\`\`bash
# Check AWS credentials
aws sts get-caller-identity

# Verify stack outputs
aws cloudformation describe-stacks --stack-name your-stack-name

# Test S3 sync (dry run)
aws s3 sync src/ s3://your-bucket-name --dryrun

# Check CloudFront distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
\`\`\`

## 💰 Cost Optimization

### Estimated Monthly Costs

For a typical small website:
- S3 storage: \$1-5/month
- CloudFront: \$1-10/month
- Route53: \$0.50/month per hosted zone
- Certificate Manager: Free
- WAF: \$1-5/month

### Cost Optimization Tips

1. Use CloudFront price class optimization
2. Enable S3 lifecycle policies for old versions
3. Monitor and set up billing alerts
4. Use S3 Intelligent Tiering for larger sites

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section
2. Review AWS CloudFormation events
3. Check CloudWatch logs
4. Open an issue in this repository

## 🔗 Useful Links

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [CloudFormation Template Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)

---

**Happy Deploying! 🚀**
\`\`\`
