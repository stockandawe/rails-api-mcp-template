# Using Rails API MCP Template with ngrok

This guide explains how to expose your Rails MCP server to the internet using ngrok, allowing remote access from anywhere.

## Prerequisites

1. [ngrok](https://ngrok.com/) installed and authenticated
2. Rails MCP server running locally on port 3001

## Setup Steps

### 1. Start Your Rails Server

Make sure your Rails app is running:

```bash
docker-compose up -d
```

### 2. Start ngrok Tunnel

Create a tunnel to your local Rails server:

```bash
ngrok http 3001
```

You'll see output like:
```
Forwarding  https://51ced4b83c38.ngrok-free.app -> http://localhost:3001
```

**Copy your ngrok URL** - you'll need it for configuration.

### 3. Configure Rails to Allow ngrok Host

The ngrok host has already been added to `config/environments/development.rb`:

```ruby
config.hosts << "51ced4b83c38.ngrok-free.app"
```

**Important**: If your ngrok URL is different, update this line with your actual ngrok subdomain.

### 4. Restart Rails Server

After updating the configuration:

```bash
docker-compose restart web
```

### 5. Test the Connection

Test the health endpoint:

```bash
curl https://YOUR_NGROK_URL.ngrok-free.app/up
```

Test the MCP endpoint:

```bash
curl -X POST https://YOUR_NGROK_URL.ngrok-free.app/mcp/messages \
  -H "Authorization: Bearer test_key_1_0b59dfe63cbc7afa06aa9d69a3fd8ccd" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "generate_random_number",
      "arguments": {"min": 1, "max": 100}
    },
    "id": 1
  }'
```

## Using with Claude Desktop

Update your `claude_desktop_config.json` to use the ngrok URL:

```json
{
  "mcpServers": {
    "rails-api-mcp-remote": {
      "command": "node",
      "args": [
        "/absolute/path/to/rails-api-mcp-template/mcp-client-bridge.js"
      ],
      "env": {
        "MCP_SERVER_URL": "https://51ced4b83c38.ngrok-free.app",
        "MCP_API_KEY": "test_key_1_0b59dfe63cbc7afa06aa9d69a3fd8ccd"
      }
    }
  }
}
```

**Replace**:
- `https://51ced4b83c38.ngrok-free.app` with your actual ngrok URL
- The API key with your actual key

Then restart Claude Desktop.

## Using with REST API Clients

You can now access the REST API from anywhere:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://YOUR_NGROK_URL.ngrok-free.app/api/v1/random?min=1&max=10"
```

## Dynamic ngrok URLs

ngrok free tier generates a new URL each time you start it. You have two options:

### Option 1: Update Configuration Each Time

1. Start ngrok: `ngrok http 3001`
2. Copy the new URL
3. Update `config/environments/development.rb` with the new host
4. Restart Rails: `docker-compose restart web`
5. Update `claude_desktop_config.json` if using Claude Desktop

### Option 2: Use ngrok Static Domain (Paid Feature)

With a paid ngrok plan, you get a static domain that doesn't change:

```bash
ngrok http 3001 --domain=your-static-domain.ngrok-app
```

Then configure once:

```ruby
# config/environments/development.rb
config.hosts << "your-static-domain.ngrok-app"
```

### Option 3: Allow All Hosts (Development Only)

**⚠️ Less secure - only for development/testing**

```ruby
# config/environments/development.rb
config.hosts.clear  # Allows any host
```

This way you don't need to update the configuration when ngrok URL changes.

## Security Considerations

### For Development/Testing

- ✅ Use API key authentication (already implemented)
- ✅ ngrok adds some security with HTTPS
- ✅ Free ngrok URLs are hard to guess
- ⚠️ Anyone with the URL and API key can access your server

### For Production Use

If you want to expose this publicly:

1. **Use a real domain** with HTTPS
2. **Implement rate limiting** (use the `rate_limit` field in clients table)
3. **Add IP allowlisting** for sensitive operations
4. **Monitor usage** and track API calls
5. **Rotate API keys** regularly
6. **Use environment-specific keys** (never use test keys in production)
7. **Consider OAuth2/JWT** for more advanced authentication

## Troubleshooting

### Rails Returns "Blocked host" Error

Update the allowed host in `config/environments/development.rb`:

```ruby
config.hosts << "YOUR_NEW_NGROK_SUBDOMAIN.ngrok-free.app"
```

Then restart: `docker-compose restart web`

### ngrok "Too Many Connections" Error

Free ngrok tier has connection limits. Consider:
- Upgrading to paid tier
- Using a different tunnel service (localtunnel, serveo)
- Deploying to a cloud service (Heroku, Render, Railway)

### API Key Not Working

Make sure:
1. You're using the correct API key from an active client
2. The `Authorization` header is properly formatted: `Bearer YOUR_KEY`
3. The client is active in the database

Check active clients:
```bash
docker-compose run --rm web rails console
```
```ruby
Client.active.pluck(:name, :api_key)
```

## Alternative Tunnel Services

If ngrok doesn't work for you, try:

### localtunnel
```bash
npx localtunnel --port 3001
```

### Cloudflare Tunnel
```bash
cloudflared tunnel --url http://localhost:3001
```

### Tailscale Funnel
```bash
tailscale funnel 3001
```

Each service requires updating the allowed host in Rails configuration.

## Sharing with Team Members

To share access with team members:

1. **Share the ngrok URL** (e.g., https://51ced4b83c38.ngrok-free.app)
2. **Create a new API client** for them:
   ```bash
   docker-compose run --rm web rails console
   ```
   ```ruby
   client = Client.create!(
     name: "Team Member Name",
     email: "member@example.com",
     active: true,
     rate_limit: 1000
   )
   puts "API Key: #{client.api_key}"
   ```
3. **Send them their API key** securely (don't send via email/slack)
4. **They can test with**:
   ```bash
   curl -H "Authorization: Bearer THEIR_API_KEY" \
     "https://YOUR_NGROK_URL.ngrok-free.app/api/v1/random"
   ```

## Monitoring Usage

Track API usage by checking Rails logs:

```bash
docker-compose logs -f web | grep "MCP\|API"
```

Or query the database to see which clients are making requests (you'd need to add logging to track this).
