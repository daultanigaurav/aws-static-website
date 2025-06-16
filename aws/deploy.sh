#!/bin/bash

# AWS Static Website Deployment Script
# This script deploys static website files to S3 and invalidates CloudFront cache

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="prod"
PROFILE=""
REGION="us-east-1"
DRY_RUN=false
VERBOSE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy static website to AWS S3 and invalidate CloudFront cache.

OPTIONS:
    -s, --stack-name STACK_NAME     CloudFormation stack name (required)
    -e, --environment ENV           Environment (dev, staging, prod) [default: prod]
    -p, --profile PROFILE           AWS CLI profile to use
    -r, --region REGION             AWS region [default: us-east-1]
    -d, --dry-run                   Show what would be deployed without actually deploying
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $0 --stack-name my-website-stack
    $0 --stack-name my-website-stack --environment staging --profile my-profile
    $0 --stack-name my-website-stack --dry-run

PREREQUISITES:
    - AWS CLI installed and configured
    - CloudFormation stack already deployed
    - Appropriate AWS permissions for S3 and CloudFront

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$STACK_NAME" ]]; then
    print_error "Stack name is required. Use --stack-name option."
    show_usage
    exit 1
fi

# Check if source directory exists
if [[ ! -d "$SRC_DIR" ]]; then
    print_error "Source directory not found: $SRC_DIR"
    exit 1
fi

# Set up AWS CLI options
AWS_CLI_OPTS=""
if [[ -n "$PROFILE" ]]; then
    AWS_CLI_OPTS="--profile $PROFILE"
fi
AWS_CLI_OPTS="$AWS_CLI_OPTS --region $REGION"

if [[ "$VERBOSE" == "true" ]]; then
    AWS_CLI_OPTS="$AWS_CLI_OPTS --debug"
fi

# Function to check AWS CLI and credentials
check_aws_setup() {
    print_status "Checking AWS CLI setup..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Test AWS credentials
    if ! aws sts get-caller-identity $AWS_CLI_OPTS &> /dev/null; then
        print_error "AWS credentials not configured or invalid."
        print_error "Please run 'aws configure' or set up your credentials."
        exit 1
    fi
    
    print_success "AWS CLI setup verified"
}

# Function to get stack outputs
get_stack_outputs() {
    print_status "Retrieving CloudFormation stack outputs..."
    
    local outputs
    outputs=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs' \
        $AWS_CLI_OPTS 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ "$outputs" == "null" ]]; then
        print_error "Failed to retrieve stack outputs. Make sure the stack exists and you have permissions."
        exit 1
    fi
    
    # Extract values
    S3_BUCKET=$(echo "$outputs" | jq -r '.[] | select(.OutputKey=="S3BucketName") | .OutputValue')
    CLOUDFRONT_DISTRIBUTION_ID=$(echo "$outputs" | jq -r '.[] | select(.OutputKey=="CloudFrontDistributionId") | .OutputValue')
    
    if [[ "$S3_BUCKET" == "null" ]] || [[ "$CLOUDFRONT_DISTRIBUTION_ID" == "null" ]]; then
        print_error "Required stack outputs not found. Make sure the CloudFormation template includes S3BucketName and CloudFrontDistributionId outputs."
        exit 1
    fi
    
    print_success "Stack outputs retrieved:"
    print_status "  S3 Bucket: $S3_BUCKET"
    print_status "  CloudFront Distribution ID: $CLOUDFRONT_DISTRIBUTION_ID"
}

# Function to sync files to S3
sync_to_s3() {
    print_status "Syncing files to S3 bucket: $S3_BUCKET"
    
    local sync_command="aws s3 sync \"$SRC_DIR\" \"s3://$S3_BUCKET\" $AWS_CLI_OPTS"
    
    # Add common sync options
    sync_command="$sync_command --delete"  # Remove files that don't exist locally
    sync_command="$sync_command --exact-timestamps"  # Use exact timestamps for comparison
    
    # Set cache control headers
    sync_command="$sync_command --cache-control \"public, max-age=31536000\""  # 1 year for static assets
    
    # Override cache control for HTML files
    local html_sync_command="aws s3 sync \"$SRC_DIR\" \"s3://$S3_BUCKET\" $AWS_CLI_OPTS"
    html_sync_command="$html_sync_command --exclude \"*\" --include \"*.html\""
    html_sync_command="$html_sync_command --cache-control \"public, max-age=0, must-revalidate\""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN MODE - Commands that would be executed:"
        echo "  $sync_command --dryrun"
        echo "  $html_sync_command --dryrun"
        return 0
    fi
    
    # Sync all files first
    if [[ "$VERBOSE" == "true" ]]; then
        print_status "Executing: $sync_command"
    fi
    
    eval "$sync_command"
    
    if [[ $? -eq 0 ]]; then
        print_success "Files synced to S3"
    else
        print_error "Failed to sync files to S3"
        exit 1
    fi
    
    # Override cache control for HTML files
    if [[ "$VERBOSE" == "true" ]]; then
        print_status "Executing: $html_sync_command"
    fi
    
    eval "$html_sync_command"
    
    if [[ $? -eq 0 ]]; then
        print_success "HTML files cache control updated"
    else
        print_warning "Failed to update HTML files cache control"
    fi
}

# Function to invalidate CloudFront cache
invalidate_cloudfront() {
    print_status "Creating CloudFront invalidation..."
    
    local invalidation_command="aws cloudfront create-invalidation"
    invalidation_command="$invalidation_command --distribution-id \"$CLOUDFRONT_DISTRIBUTION_ID\""
    invalidation_command="$invalidation_command --paths \"/*\""
    invalidation_command="$invalidation_command $AWS_CLI_OPTS"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN MODE - Command that would be executed:"
        echo "  $invalidation_command"
        return 0
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        print_status "Executing: $invalidation_command"
    fi
    
    local invalidation_result
    invalidation_result=$(eval "$invalidation_command")
    
    if [[ $? -eq 0 ]]; then
        local invalidation_id
        invalidation_id=$(echo "$invalidation_result" | jq -r '.Invalidation.Id')
        print_success "CloudFront invalidation created: $invalidation_id"
        print_status "Invalidation typically takes 10-15 minutes to complete"
    else
        print_error "Failed to create CloudFront invalidation"
        exit 1
    fi
}

# Function to show deployment summary
show_summary() {
    print_success "Deployment Summary:"
    echo "  Stack Name: $STACK_NAME"
    echo "  Environment: $ENVIRONMENT"
    echo "  S3 Bucket: $S3_BUCKET"
    echo "  CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
    echo "  Region: $REGION"
    if [[ -n "$PROFILE" ]]; then
        echo "  AWS Profile: $PROFILE"
    fi
    echo "  Source Directory: $SRC_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "This was a DRY RUN - no actual changes were made"
    else
        print_success "Deployment completed successfully!"
    fi
}

# Main execution
main() {
    print_status "Starting deployment process..."
    print_status "Stack: $STACK_NAME, Environment: $ENVIRONMENT"
    
    # Check prerequisites
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    check_aws_setup
    get_stack_outputs
    sync_to_s3
    invalidate_cloudfront
    show_summary
}

# Run main function
main "$@"
