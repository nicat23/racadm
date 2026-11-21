# GitHub Actions Setup Guide

## Overview

The repository now includes automated CI/CD via GitHub Actions to build and push Docker images to DockerHub and GitHub Container Registry (GHCR).

## Configuration Required

### 1. DockerHub Credentials

Add the following secrets to your GitHub repository:

**Repository Settings → Secrets and variables → Actions**

- **`DOCKERHUB_USERNAME`**: Your DockerHub username
- **`DOCKERHUB_TOKEN`**: DockerHub Personal Access Token

#### How to Create a DockerHub Personal Access Token:

1. Log in to [DockerHub](https://hub.docker.com)
2. Navigate to **Account Settings → Security**
3. Click **New Access Token**
4. Give it a descriptive name (e.g., `github-actions`)
5. Set appropriate permissions (at minimum: Read & Write)
6. Copy the token and add it to GitHub Secrets

### 2. GitHub Token

The workflow automatically uses `${{ secrets.GITHUB_TOKEN }}` for GHCR authentication. No manual setup needed!

## Workflow Triggers

The workflow is triggered in two ways:

### Automatic Trigger
- **When**: Changes pushed to `main` branch
- **What changes**: Only when `Dockerfile` or `.github/workflows/build.yaml` changes
- **Tags applied**: 
  - `nicat23/racadm:latest`
  - `nicat23/racadm:latest-{short-sha}`
  - GHCR equivalents

### Manual Trigger (Workflow Dispatch)
- **How**: Go to **Actions → Build and Push racadm Image → Run workflow**
- **Options**:
  - Leave `image_tag` empty for automatic tagging
  - Or provide a custom tag (e.g., `v1.0.0`, `staging`, etc.)

## Published Images

After setup, your images will be available at:

- **DockerHub**: `nicat23/racadm:latest`, `nicat23/racadm:latest-{sha}`, or custom tags
- **GHCR**: `ghcr.io/{username}/racadm:latest`, etc.

## Example Usage

Pull the automatically built image:

```bash
docker pull nicat23/racadm:latest
```

Or with a specific commit:

```bash
docker pull nicat23/racadm:latest-abc1234
```

## Monitoring Builds

1. Go to **Actions** tab in your GitHub repository
2. Click on **Build and Push racadm Image**
3. View build logs and status for each workflow run

## Troubleshooting

### Build Fails to Push

**Problem**: "Invalid username or token"

**Solution**: 
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are correctly set
- Ensure the token hasn't expired (create a new one if needed)
- Confirm the token has Read & Write permissions

### GHCR Errors

**Problem**: "Failed to authenticate"

**Solution**: 
- This should work automatically with `GITHUB_TOKEN`
- If issues persist, check repository Actions permissions under **Settings → Actions → General → Workflow permissions**
- Ensure "Read and write permissions" is selected

### Build Cache Not Working

**Problem**: Each build takes much longer

**Solution**: 
- GitHub Actions cache should work automatically
- Builds get faster after the first run
- If still slow, check that `cache-from` and `cache-to` are present in the workflow

## Best Practices

1. **Keep DockerHub credentials secure**: 
   - Use Personal Access Tokens, not passwords
   - Regenerate tokens periodically
   - Delete old tokens when no longer needed

2. **Tag releases properly**:
   - Use semantic versioning (e.g., `v1.0.0`, `v1.0.1`)
   - Use the manual dispatch with custom tag for releases

3. **Monitor build logs**:
   - Review logs for any warnings or deprecated dependencies
   - Fix issues early before they become problems

## Security Considerations

- Secrets are encrypted and only exposed to Actions during runs
- DockerHub token is never logged or displayed
- Both DockerHub and GHCR support private images if needed
- Consider setting image visibility to "Private" on GHCR if desired
