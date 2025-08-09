# Deployment with GitHub Actions and Kamal

This project uses GitHub Actions to automatically deploy to production using Kamal when changes are pushed to the `master` branch.

## Required GitHub Secrets

To set up deployment, you need to configure the following secrets in your GitHub repository settings (Settings → Secrets and variables → Actions → Repository secrets):

### Docker Registry Secrets
- `DOCKER_USERNAME`: Your Docker Hub username (`emcousin`)
- `DOCKER_PASSWORD`: Your Docker Hub access token or password

### SSH Access
- `SSH_PRIVATE_KEY`: Private SSH key for accessing the production server (46.255.164.98)
  - Make sure the corresponding public key is added to the server's `~/.ssh/authorized_keys`

### Rails Application Secrets
- `RAILS_MASTER_KEY`: Rails master key for decrypting credentials
  - You can find this in your local `config/master.key` file

### Database Secrets
- `POSTGRES_PASSWORD`: Password for the PostgreSQL database user (`rails`)
- `GRAFANA_POSTGRES_PASSWORD`: Password for Grafana PostgreSQL access

### S3 Backup Secrets (for database backups)
- `S3_ACCESS_KEY_ID`: S3-compatible storage access key ID
- `S3_SECRET_ACCESS_KEY`: S3-compatible storage secret access key
- `S3_ENDPOINT`: S3-compatible storage endpoint URL

## Deployment Process

The deployment workflow:

1. **Triggers**: Automatically runs when code is pushed to `master` branch, or can be manually triggered
2. **Build**: Sets up Ruby, Docker, and installs Kamal
3. **Authentication**: Logs into Docker Hub and sets up SSH access to the server
4. **Secrets**: Creates the `.kamal/secrets` file with all required environment variables
5. **Deploy**: Runs `kamal deploy` to build and deploy the application

## Manual Deployment

You can also deploy manually from your local machine:

```bash
# Make sure you have the .kamal/secrets file with all required secrets
bin/deploy
```

## Server Configuration

The application deploys to:
- **Host**: 46.255.164.98
- **Domain**: inscriptions.parkourparis.fr
- **SSL**: Automatically managed by Let's Encrypt
- **Database**: PostgreSQL 17 Alpine
- **Backup**: Daily S3 backups with 7-day retention

## Environment Variables

The following environment variables are automatically set in the production environment:

- `SOLID_QUEUE_IN_PUMA=true`: Run background jobs in Puma
- `DB_HOST=pkp-db`: Database host
- `DOCKER=true`: Indicates Docker environment
- `RAILS_SERVE_STATIC_FILES=true`: Serve static assets

## Troubleshooting

1. **SSH Access Issues**: Make sure your SSH private key is correctly formatted and the public key is on the server
2. **Docker Issues**: Verify Docker Hub credentials and repository permissions
3. **Rails Issues**: Check that the `RAILS_MASTER_KEY` matches your production credentials
4. **Database Issues**: Verify PostgreSQL passwords and connection settings

## Security Notes

- Never commit secrets to the repository
- Use GitHub repository secrets for sensitive data
- Regularly rotate access keys and passwords
- Monitor deployment logs for any security issues
