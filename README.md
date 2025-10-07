# Rails API + MCP Server Template

A proof-of-concept Rails application that serves as both a **RESTful API** and a **Model Context Protocol (MCP) server**. This template demonstrates how to build a unified backend that can serve traditional REST API clients and MCP-enabled applications with shared authentication and business logic.

## Features

- **REST API**: Standard RESTful endpoints with JSON responses
- **MCP Server**: Model Context Protocol server with tool support
- **Unified Authentication**: API_KEY based authentication for both REST and MCP
- **Client Management**: PostgreSQL-backed client database with rate limiting support
- **Docker Support**: Complete Docker setup for local development
- **Shared Business Logic**: Service layer that both REST and MCP endpoints use

## Tech Stack

- **Ruby**: 3.3.9
- **Rails**: 7.2.2
- **PostgreSQL**: 16 (Alpine)
- **Docker**: For containerized development

## Project Structure

```
rails-api-mcp-template/
├── app/
│   ├── controllers/
│   │   ├── api/v1/              # REST API controllers
│   │   │   ├── base_controller.rb
│   │   │   └── random_numbers_controller.rb
│   │   ├── mcp/                  # MCP server controllers
│   │   │   └── server_controller.rb
│   │   └── concerns/
│   │       └── api_key_authenticatable.rb  # Shared authentication
│   ├── models/
│   │   └── client.rb             # Client model with API key management
│   └── services/
│       └── random_number_service.rb  # Shared business logic
├── config/
│   ├── database.yml              # PostgreSQL configuration
│   └── routes.rb                 # API and MCP routes
├── db/
│   ├── migrate/
│   └── seeds.rb                  # Test data
├── docker-compose.yml            # Docker services
└── Dockerfile.dev                # Development Dockerfile
```

## Getting Started

### Prerequisites

- Docker and Docker Compose installed on your system

### Setup

1. **Clone or copy this template to your project directory**

2. **Start the services**:
   ```bash
   docker-compose up -d
   ```

3. **Create and migrate the database**:
   ```bash
   docker-compose run --rm web bash -c "bundle install && rails db:create db:migrate"
   ```

4. **Seed the database with test clients**:
   ```bash
   docker-compose run --rm web rails db:seed
   ```

   Save the API keys displayed in the output - you'll need them for testing!

5. **Access the application**:
   - REST API: http://localhost:3001/api/v1
   - MCP Server: http://localhost:3001/mcp
   - Health Check: http://localhost:3001/up

### Connecting to Claude Desktop

To use this MCP server with Claude Desktop, see **[CLAUDE_DESKTOP_SETUP.md](./CLAUDE_DESKTOP_SETUP.md)** for detailed configuration instructions.

**Quick Setup**:

1. Add to your `claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "rails-api-mcp": {
         "command": "node",
         "args": ["/absolute/path/to/mcp-client-bridge.js"],
         "env": {
           "MCP_SERVER_URL": "http://localhost:3001",
           "MCP_API_KEY": "your_api_key_here"
         }
       }
     }
   }
   ```

2. Restart Claude Desktop

See the full guide for troubleshooting and examples.

## MCP Transport Architecture

### Why the Bridge Script?

This Rails MCP server uses **HTTP transport** (POST requests to `/mcp/messages`), while most MCP clients like Claude Desktop expect **stdio transport** (standard input/output). The `mcp-client-bridge.js` script acts as a protocol adapter between these two transport mechanisms.

**Transport Types**:

| Transport | How It Works | Used By |
|-----------|-------------|---------|
| **stdio** | Communicates via stdin/stdout (like a command-line program) | Claude Desktop, most MCP clients |
| **HTTP** | Communicates via HTTP requests (like a web API) | Web applications, curl, Postman |

**When You Need the Bridge**:

- ✅ **Claude Desktop** - Requires stdio, so you MUST use the bridge
- ✅ **Other stdio-based MCP clients** - Any client expecting stdin/stdout
- ❌ **Direct HTTP clients** - Can connect directly to `http://localhost:3001/mcp/messages`
- ❌ **Custom integrations** - Can use the HTTP API directly without the bridge

**Direct HTTP Usage (No Bridge Needed)**:

If you're building your own MCP client or integration, you can communicate directly with the HTTP endpoints:

```bash
# Initialize connection
curl -X POST http://localhost:3001/mcp/messages \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}},"id":1}'

# List available tools
curl -X POST http://localhost:3001/mcp/messages \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'

# Call a tool
curl -X POST http://localhost:3001/mcp/messages \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"generate_random_number","arguments":{"min":1,"max":50}},"id":3}'
```

**Alternative Approaches**:

1. **Native stdio MCP server**: Rewrite the MCP server to use stdin/stdout directly (eliminates the need for the bridge)
2. **Use this HTTP approach**: Allows the same server to handle both REST API and MCP requests
3. **Separate servers**: Run a dedicated stdio MCP server and a separate REST API server

This template uses the **HTTP approach** because it allows:
- Single codebase for both REST API and MCP
- Shared authentication and business logic
- Easy testing with curl/Postman
- Web-based MCP clients can connect directly

The bridge script is a lightweight adapter (< 100 lines) that translates between stdio and HTTP, making it easy to connect stdio-based clients like Claude Desktop.

### Remote Access with ngrok

To expose your MCP server over the internet (for remote access or sharing), use ngrok or similar tunneling services:

```bash
# Start ngrok tunnel
ngrok http 3001
```

Then update `config/environments/development.rb` with your ngrok URL and use it in the bridge configuration. See **[NGROK_SETUP.md](./NGROK_SETUP.md)** for complete setup instructions, security considerations, and troubleshooting.

**Quick ngrok config**:
1. Add to `config/environments/development.rb`: `config.hosts << "your-subdomain.ngrok-free.app"`
2. Restart Rails: `docker-compose restart web`
3. Update bridge to use: `"MCP_SERVER_URL": "https://your-subdomain.ngrok-free.app"`

## Authentication

Both REST API and MCP server use **API_KEY authentication**. The API key can be provided in three ways (in order of preference):

1. **Authorization header** (recommended):
   ```
   Authorization: Bearer YOUR_API_KEY
   ```

2. **X-API-Key header**:
   ```
   X-API-Key: YOUR_API_KEY
   ```

3. **Query parameter** (for testing only):
   ```
   ?api_key=YOUR_API_KEY
   ```

## REST API Usage

### Get Random Number

Generate a random number within an optional range.

**Endpoint**: `GET /api/v1/random`

**Headers**:
```
Authorization: Bearer YOUR_API_KEY
```

**Query Parameters**:
- `min` (optional): Minimum value (default: 1)
- `max` (optional): Maximum value (default: 100)

**Example Request**:
```bash
curl -H "Authorization: Bearer test_key_1_0b59dfe63cbc7afa06aa9d69a3fd8ccd" \
  "http://localhost:3001/api/v1/random?min=1&max=10"
```

**Example Response**:
```json
{
  "number": 7,
  "min": 1,
  "max": 10,
  "client": "Test Client 1",
  "timestamp": "2025-10-07T21:58:20Z"
}
```

## MCP Server Usage

The MCP server implements the Model Context Protocol, allowing MCP clients to discover and call tools.

### Available MCP Endpoints

#### 1. Initialize Connection

**Endpoint**: `POST /mcp/messages`

**Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "id": 1
}
```

**Headers**:
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
```

#### 2. List Available Tools

**Endpoint**: `POST /mcp/messages`

**Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 1
}
```

#### 3. Call a Tool

**Endpoint**: `POST /mcp/messages`

**Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "generate_random_number",
    "arguments": {
      "min": 1,
      "max": 100
    }
  },
  "id": 1
}
```

**Example with curl**:
```bash
curl -X POST http://localhost:3001/mcp/messages \
  -H "Authorization: Bearer test_key_1_0b59dfe63cbc7afa06aa9d69a3fd8ccd" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "generate_random_number",
      "arguments": {"min": 1, "max": 50}
    },
    "id": 1
  }'
```

#### 4. Server-Sent Events (SSE)

**Endpoint**: `GET /mcp/sse`

Connect to receive server-sent events:
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3001/mcp/sse
```

## Client Management

### Creating New Clients

You can create new API clients programmatically or via Rails console:

```bash
docker-compose run --rm web rails console
```

```ruby
# Create a new client
client = Client.create!(
  name: "My Application",
  email: "app@example.com",
  active: true,
  rate_limit: 1000
)

# The API key is automatically generated
puts client.api_key
```

### Client Fields

- `name` (required): Client identifier
- `email` (optional): Contact email (must be unique)
- `api_key` (auto-generated): 64-character hex string
- `active` (default: true): Whether the client can access the API
- `rate_limit` (default: 1000): Requests per time period

## Development

### Running Rails Console

```bash
docker-compose run --rm web rails console
```

### Running Database Migrations

```bash
docker-compose run --rm web rails db:migrate
```

### Viewing Logs

```bash
docker-compose logs -f web
```

### Stopping Services

```bash
docker-compose down
```

### Rebuilding After Changes

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

## Adding New Endpoints

### REST API Endpoint

1. Create a controller in `app/controllers/api/v1/`
2. Inherit from `Api::V1::BaseController` (includes authentication)
3. Add routes in `config/routes.rb` under the `api` namespace

### MCP Tool

1. Add tool definition in `handle_tools_list` method
2. Add tool implementation in `handle_tool_call` method
3. Both in `app/controllers/mcp/server_controller.rb`

### Shared Service

1. Create a service class in `app/services/`
2. Use it from both REST and MCP controllers

## Testing Credentials

After running `rails db:seed`, you'll have these test clients (your keys will be different):

**Test Client 1**:
- Email: client1@example.com
- Rate Limit: 1000 requests
- Status: Active

**Test Client 2**:
- Email: client2@example.com
- Rate Limit: 500 requests
- Status: Active

## Security Notes

- **API Keys**: In production, use environment variables or a secrets manager
- **HTTPS**: Always use HTTPS in production
- **Rate Limiting**: Implement rate limiting based on the `rate_limit` field
- **CORS**: Configure CORS in `config/initializers/cors.rb` if needed
- **Database**: Use strong passwords in production

## Extending This Template

This template is designed to be a starting point. Consider adding:

- **Rate limiting middleware**: Enforce the `rate_limit` field
- **Logging**: Track API usage per client
- **More MCP tools**: Add additional tools to the MCP server
- **REST endpoints**: Expand the REST API
- **Authentication methods**: Add OAuth2, JWT, etc.
- **Background jobs**: Use Sidekiq for async processing
- **Caching**: Add Redis for caching
- **API documentation**: Use Swagger/OpenAPI
- **Tests**: Add RSpec or Minitest

## MCP Protocol Resources

- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [MCP Documentation](https://modelcontextprotocol.io/)

## License

This template is provided as-is for educational and development purposes.
