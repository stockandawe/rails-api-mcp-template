# Security Guidelines

## Files Already Protected

The following sensitive files are automatically excluded from git (via `.gitignore`):

✅ `/config/master.key` - Rails master encryption key
✅ `/.env*` - Environment variable files
✅ `/log/*` - Log files (may contain sensitive data)
✅ `/tmp/*` - Temporary files
✅ `/storage/*` - Uploaded files

## Example/Test Data in Repository

This repository includes **example test data** for demonstration purposes:

- **Test API Keys** in `db/seeds.rb`:
  - `test_key_1_*` and `test_key_2_*`
  - These are randomly generated during seeding
  - **Safe to commit** - they're examples only

- **Example Configuration Files**:
  - `claude_desktop_config.example.json`
  - `.env.example`
  - These use placeholders like `your_api_key_here`

## Before Deploying to Production

### 1. Update Configuration

**Never use the test/example credentials in production:**

```bash
# Generate new master key
rm config/master.key config/credentials.yml.enc
EDITOR=nano rails credentials:edit

# Create production API clients with strong keys
rails console
Client.create!(
  name: "Production Client",
  email: "prod@example.com",
  active: true,
  rate_limit: 10000
)
```

### 2. Environment Variables

Use environment variables for sensitive configuration:

```bash
# Production environment
RAILS_ENV=production
DATABASE_URL=postgresql://user:password@host:5432/dbname
RAILS_MASTER_KEY=your_production_master_key
```

### 3. Security Checklist

- [ ] Change all API keys from test/example values
- [ ] Use HTTPS only (no HTTP)
- [ ] Implement rate limiting (use the `rate_limit` field)
- [ ] Enable CORS properly for your domain
- [ ] Use strong, unique passwords for database
- [ ] Rotate API keys regularly
- [ ] Monitor API usage and logs
- [ ] Keep Rails and all gems updated
- [ ] Use a secret manager (AWS Secrets Manager, HashiCorp Vault, etc.)

## Local Development Security

### Docker Secrets

For team development, consider using Docker secrets instead of environment variables:

```yaml
# docker-compose.yml
services:
  web:
    secrets:
      - database_password

secrets:
  database_password:
    file: ./secrets/db_password.txt
```

**Add to `.gitignore`:**
```
secrets/
```

### API Key Management

**For local development:**
1. Run `rails db:seed` to generate test keys
2. Store your personal test key in `.env` (already in `.gitignore`)
3. Never commit `.env` files

**For team sharing:**
1. Each developer gets their own API client
2. Use `.env.example` as a template
3. Share keys through secure channels (1Password, LastPass, etc.)

## Reporting Security Issues

If you find a security vulnerability, please:

1. **Do NOT open a public issue**
2. Email the maintainer directly
3. Include details about the vulnerability
4. Allow time for a fix before public disclosure

## Additional Resources

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [API Security Best Practices](https://apisecurity.io/encyclopedia/content/api-security-best-practices.htm)
