module Mcp
  class ServerController < ApplicationController
    include ApiKeyAuthenticatable
    include ActionController::Live

    # POST /mcp/messages
    # Handle MCP protocol messages
    def handle_message
      request_data = JSON.parse(request.body.read)
      request_id = request_data["id"]

      response = case request_data["method"]
      when "initialize"
        handle_initialize(request_id)
      when "tools/list"
        handle_tools_list(request_id)
      when "tools/call"
        handle_tool_call(request_data["params"], request_id)
      else
        {
          jsonrpc: "2.0",
          error: {
            code: -32601,
            message: "Method not found"
          },
          id: request_id
        }
      end

      render json: response
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :bad_request
    end

    # GET /mcp/sse
    # Server-Sent Events endpoint for MCP
    def sse
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["X-Accel-Buffering"] = "no"

      sse = SSE.new(response.stream)

      begin
        # Send initial connection message
        sse.write({ type: "connected", client: @current_client.name }, event: "message")

        # Keep connection alive
        loop do
          sleep 30
          sse.write({ type: "ping" }, event: "ping")
        end
      rescue IOError
        # Client disconnected
      ensure
        sse.close
      end
    end

    private

    def handle_initialize(request_id)
      {
        jsonrpc: "2.0",
        result: {
          protocolVersion: "2024-11-05",
          serverInfo: {
            name: "Rails API MCP Server",
            version: "1.0.0"
          },
          capabilities: {
            tools: {}
          }
        },
        id: request_id
      }
    end

    def handle_tools_list(request_id)
      {
        jsonrpc: "2.0",
        result: {
          tools: [
            {
              name: "generate_random_number",
              description: "Generate a random number within a specified range",
              inputSchema: {
                type: "object",
                properties: {
                  min: {
                    type: "integer",
                    description: "Minimum value (default: 1)",
                    default: 1
                  },
                  max: {
                    type: "integer",
                    description: "Maximum value (default: 100)",
                    default: 100
                  }
                }
              }
            }
          ]
        },
        id: request_id
      }
    end

    def handle_tool_call(params, request_id)
      tool_name = params["name"]
      arguments = params["arguments"] || {}

      case tool_name
      when "generate_random_number"
        min = arguments["min"]&.to_i || 1
        max = arguments["max"]&.to_i || 100

        number = RandomNumberService.generate(min: min, max: max)

        {
          jsonrpc: "2.0",
          result: {
            content: [
              {
                type: "text",
                text: "Generated random number: #{number} (range: #{min}-#{max})"
              }
            ],
            isError: false
          },
          id: request_id
        }
      else
        {
          jsonrpc: "2.0",
          error: {
            code: -32602,
            message: "Unknown tool: #{tool_name}"
          },
          id: request_id
        }
      end
    rescue ArgumentError => e
      {
        jsonrpc: "2.0",
        result: {
          content: [
            {
              type: "text",
              text: "Error: #{e.message}"
            }
          ],
          isError: true
        },
        id: request_id
      }
    end
  end

  # Simple SSE helper class
  class SSE
    def initialize(stream)
      @stream = stream
    end

    def write(object, event: nil)
      @stream.write("event: #{event}\n") if event
      @stream.write("data: #{object.to_json}\n\n")
    end

    def close
      @stream.close
    end
  end
end
