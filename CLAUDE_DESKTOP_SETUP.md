# Claude Desktop Configuration Guide

This guide shows you how to connect Claude Desktop to your Rails MCP server.

## Prerequisites

1. Rails MCP server running on `http://localhost:3001`
2. Node.js installed (for the bridge script)
3. An API key from the database (obtained from `rails db:seed`)

## Configuration Steps

### 1. Get Your API Key

Run the Rails console to get your API key:

```bash
docker-compose run --rm web rails console
```

Then in the console:

```ruby
# Get an active client's API key
client = Client.active.first
puts client.api_key
# Copy this key!
```

Or check the output from when you ran `rails db:seed` earlier.

### 2. Configure Claude Desktop

Find your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Windows**: `%APPDATA%/Claude/claude_desktop_config.json`

**Linux**: `~/.config/Claude/claude_desktop_config.json`

### 3. Add MCP Server Configuration

Edit `claude_desktop_config.json` and add:

```json
{
  "mcpServers": {
    "rails-api-mcp": {
      "command": "node",
      "args": [
        "/absolute/path/to/rails-api-mcp-template/mcp-client-bridge.js"
      ],
      "env": {
        "MCP_SERVER_URL": "http://localhost:3001",
        "MCP_API_KEY": "test_key_1_0b59dfe63cbc7afa06aa9d69a3fd8ccd"
      }
    }
  }
}
```

**Important**: Replace:
- The path to `mcp-client-bridge.js` with your actual absolute path
- The `MCP_API_KEY` with your actual API key from step 1

### 4. Restart Claude Desktop

Completely quit and restart Claude Desktop for the changes to take effect.

### 5. Verify Connection

In Claude Desktop, you should now be able to use the MCP tools. Try asking Claude:

> "Can you use the generate_random_number tool to give me a random number between 1 and 100?"

## Troubleshooting

### Bridge Script Not Found

Make sure the path in `claude_desktop_config.json` is the **absolute path** to `mcp-client-bridge.js`.

To get the absolute path:

```bash
cd /path/to/rails-api-mcp-template
pwd
# Use this path + /mcp-client-bridge.js
```

### API Key Invalid

Make sure:
1. The Rails server is running: `docker-compose up -d`
2. The API key is from an active client
3. The API key is correctly copied (no extra spaces)

Check active clients:

```bash
docker-compose run --rm web rails console
```

```ruby
Client.active.each do |c|
  puts "#{c.name}: #{c.api_key}"
end
```

### Server Not Responding

Verify the Rails server is running:

```bash
curl http://localhost:3001/up
```

Should return a green HTML page.

Check Docker containers:

```bash
docker-compose ps
```

### View Bridge Logs

Claude Desktop typically logs MCP server output. Check:

**macOS**: `~/Library/Logs/Claude/`

**Windows**: `%APPDATA%/Claude/logs/`

## Example Usage in Claude Desktop

Once configured, you can ask Claude to use the tools:

1. **Generate a random number**:
   > "Use the generate_random_number tool to get a random number between 1 and 50"

2. **Check available tools**:
   > "What MCP tools do you have access to from the rails-api-mcp server?"

## Configuration for Multiple Environments

You can configure different environments:

```json
{
  "mcpServers": {
    "rails-api-mcp-local": {
      "command": "node",
      "args": ["/path/to/mcp-client-bridge.js"],
      "env": {
        "MCP_SERVER_URL": "http://localhost:3001",
        "MCP_API_KEY": "your_dev_key"
      }
    },
    "rails-api-mcp-ngrok": {
      "command": "node",
      "args": ["/path/to/mcp-client-bridge.js"],
      "env": {
        "MCP_SERVER_URL": "https://your-subdomain.ngrok-free.app",
        "MCP_API_KEY": "your_dev_key"
      }
    },
    "rails-api-mcp-prod": {
      "command": "node",
      "args": ["/path/to/mcp-client-bridge.js"],
      "env": {
        "MCP_SERVER_URL": "https://your-production-server.com",
        "MCP_API_KEY": "your_prod_key"
      }
    }
  }
}
```

### Using with ngrok (Remote Access)

To access your Rails MCP server remotely via ngrok:

1. **Start ngrok**: `ngrok http 3001`
2. **Configure Rails** to allow the ngrok host (see [NGROK_SETUP.md](./NGROK_SETUP.md))
3. **Update bridge URL** to use your ngrok URL in the config above
4. **Restart Claude Desktop**

This allows you to access your local Rails server from Claude Desktop on any machine!

## Security Notes

- **Never commit** your `claude_desktop_config.json` with API keys
- Use environment-specific API keys
- Rotate API keys regularly
- For production, use HTTPS only
