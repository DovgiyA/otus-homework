# GitLab CI/CD Variables Configuration Guide

This document describes all required GitLab CI/CD variables for the deployment pipeline.

## Required Variables

### Kubernetes Configuration
- **`KUBE_CONFIG`** (Variable type: File | Protected: Yes | Masked: No)
  - Base64-encoded kubeconfig file for cluster access
  - Generate with: `cat ~/.kube/config | base64 -w 0`
  - Required for: All deployment stages

### Database Variables (MySQL)
- **`MYSQL_ROOT_PASSWORD`** (Variable type: Variable | Protected: Yes | Masked: Yes)
  - MySQL root password
  - Default: `rootpassword` (change in production!)
  - Required for: deploy_mysql stage

- **`MYSQL_USER`** (Variable type: Variable | Protected: Yes | Masked: No)
  - MySQL application user
  - Default: `speedtest`
  - Required for: deploy_mysql stage

- **`MYSQL_PASSWORD`** (Variable type: Variable | Protected: Yes | Masked: Yes)
  - MySQL application user password
  - Default: `speedtestpassword` (change in production!)
  - Required for: deploy_mysql stage

- **`MYSQL_DATABASE`** (Variable type: Variable | Protected: Yes | Masked: No)
  - MySQL database name
  - Default: `speedtest_telemetry`
  - Required for: deploy_mysql stage

### Application Variables (LibreSpeed)
- **`DB_PASSWORD`** (Variable type: Variable | Protected: Yes | Masked: Yes)
  - Database password for LibreSpeed application
  - Should match `MYSQL_PASSWORD`
  - Default: `speedtestpassword` (change in production!)
  - Required for: deploy_librespeed stage

- **`STATS_PASSWORD`** (Variable type: Variable | Protected: Yes | Masked: Yes)
  - Password for accessing statistics
  - Default: `statspassword` (change in production!)
  - Required for: deploy_librespeed stage

- **`OBFUSCATION_SALT`** (Variable type: Variable | Protected: Yes | Masked: Yes)
  - Salt for ID obfuscation
  - Default: `0x1234abcd` (use random value in production!)
  - Required for: deploy_librespeed stage

### Container Registry Variables
- **`REGISTRY_USERNAME`** (Variable type: Variable | Protected: Yes | Masked: No)
  - Username for container registry
  - Default: `pull-creds`
  - Required for: deploy_librespeed stage

- **`REGISTRY_PASSWORD`** (Variable type: Variable | Protected: Yes | Masked: Yes)
  - Password/token for container registry
  - Default: `gldt-HtG_JHBMXyzCCiJAgpzh` (use proper token in production!)
  - Required for: deploy_librespeed stage

### Optional Variables
- **`REGISTRY_URL`** (Variable type: Variable | Protected: No | Masked: No)
  - Container registry URL
  - Default: `registry.rebrainme.com`

- **`IMAGE_TAG`** (Variable type: Variable | Protected: No | Masked: No)
  - Docker image tag to deploy
  - Default: `5.3`

- **`DB_HOSTNAME`** (Variable type: Variable | Protected: No | Masked: No)
  - Database hostname
  - Default: `mysql.db.svc.cluster.local`

- **`STORAGE_CLASS`** (Variable type: Variable | Protected: No | Masked: No)
  - Kubernetes storage class
  - Default: `local-path`

- **`STORAGE_SIZE`** (Variable type: Variable | Protected: No | Masked: No)
  - Persistent volume size
  - Default: `1Gi`

## Setting Variables in GitLab

### via GitLab UI
1. Go to **Settings > CI/CD > Variables**
2. Click **Add variable**
3. Fill in the key, value, and select appropriate options
4. Click **Add variable**

### via GitLab CLI
```bash
# For protected, masked variables
glab ci-variable set --protected --masked MYSQL_PASSWORD "your-secure-password"

# For file variables
glab ci-variable set --type=file KUBE_CONFIG < ~/.kube/config.base64
```

## Variable Types

### Variable
- Standard key-value pair
- Use for: Configuration values, passwords, tokens
- Mask sensitive values to hide them in logs

### File
- Content treated as a file
- Use for: Kubeconfig, certificates, multi-line configs
- Cannot be masked

## Protection & Masking

### Protected Variables
- Only available in protected branches/tags
- Use for: Production credentials, sensitive configs
- Recommended: Yes for all sensitive variables

### Masked Variables
- Hidden in job logs
- Requirements: Single line, no special characters, base64-encoded if needed
- Use for: Passwords, tokens, API keys
- Cannot be used with File type

## Security Best Practices

1. **Never commit secrets to the repository**
2. **Use different passwords for development/staging/production**
3. **Rotate credentials regularly**
4. **Use GitLab Protected Variables for production secrets**
5. **Enable Masked Variables for sensitive data**
6. **Use GitLab Environments** for different deployment targets
7. **Review variable access permissions regularly**
8. **Use GitLab's integrated secrets management** where available

## Variable Validation

The pipeline includes validation to ensure all required variables are set before deployment. Missing variables will cause the pipeline to fail with a clear error message.

## Troubleshooting

### "variable not set" errors
- Check that all required variables are defined in GitLab CI/CD settings
- Verify variable names match exactly (case-sensitive)
- Ensure variables are available in the current branch/environment

### Permission denied on KUBE_CONFIG
- Verify the kubeconfig has proper permissions
- Ensure the ServiceAccount has adequate RBAC permissions
- Check that the cluster is accessible from GitLab runners

### Authentication failures
- Verify registry credentials are correct and not expired
- Check that registry URL is accessible from the cluster
- Ensure image pull secrets are properly configured

## Environment-Specific Variables

Consider using GitLab Environments for different stages:

### Development
- Less restrictive passwords
- Debug enabled
- Smaller resource allocations

### Staging
- Production-like configuration
- Separate database instances
- Full monitoring

### Production
- Strong, unique passwords
- Optimized resource settings
- Enhanced security measures
- Backup and recovery procedures
