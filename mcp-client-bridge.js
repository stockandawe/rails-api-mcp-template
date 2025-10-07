#!/usr/bin/env node

/**
 * MCP stdio-to-HTTP Bridge for Claude Desktop
 *
 * This script acts as a bridge between Claude Desktop (which uses stdio)
 * and the Rails HTTP-based MCP server.
 */

const readline = require('readline');
const https = require('http');

// Configuration
const MCP_SERVER_URL = process.env.MCP_SERVER_URL || 'http://localhost:3001';
const API_KEY = process.env.MCP_API_KEY;

if (!API_KEY) {
  console.error('Error: MCP_API_KEY environment variable is required');
  process.exit(1);
}

// Create readline interface for stdio
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

// Function to send HTTP request to Rails MCP server
async function sendToMCPServer(message) {
  return new Promise((resolve, reject) => {
    const url = new URL('/mcp/messages', MCP_SERVER_URL);
    const data = JSON.stringify(message);

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length,
        'Authorization': `Bearer ${API_KEY}`
      }
    };

    const req = https.request(url, options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const jsonResponse = JSON.parse(responseData);
          resolve(jsonResponse);
        } catch (error) {
          reject(new Error(`Failed to parse response: ${error.message}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

// Handle incoming messages from Claude Desktop (via stdin)
rl.on('line', async (line) => {
  try {
    const message = JSON.parse(line);

    // Forward to Rails MCP server
    const response = await sendToMCPServer(message);

    // Send response back to Claude Desktop (via stdout)
    console.log(JSON.stringify(response));
  } catch (error) {
    // Send error response back to Claude Desktop
    const errorResponse = {
      jsonrpc: '2.0',
      error: {
        code: -32603,
        message: error.message
      },
      id: null
    };
    console.log(JSON.stringify(errorResponse));
  }
});

rl.on('close', () => {
  process.exit(0);
});

// Handle process termination
process.on('SIGINT', () => {
  process.exit(0);
});

process.on('SIGTERM', () => {
  process.exit(0);
});
