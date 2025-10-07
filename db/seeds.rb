# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create test clients
clients = [
  {
    name: "Test Client 1",
    email: "client1@example.com",
    api_key: "test_key_1_#{SecureRandom.hex(16)}",
    active: true,
    rate_limit: 1000
  },
  {
    name: "Test Client 2",
    email: "client2@example.com",
    api_key: "test_key_2_#{SecureRandom.hex(16)}",
    active: true,
    rate_limit: 500
  },
  {
    name: "Inactive Client",
    email: "inactive@example.com",
    api_key: "inactive_key_#{SecureRandom.hex(16)}",
    active: false,
    rate_limit: 100
  }
]

clients.each do |client_data|
  client = Client.find_or_initialize_by(email: client_data[:email])
  client.update!(client_data)
  puts "Created/Updated client: #{client.name} (API Key: #{client.api_key})"
end

puts "Seeding complete!"
puts "\n" + "=" * 80
puts "IMPORTANT: Save these API keys for testing:"
puts "=" * 80
Client.active.each do |client|
  puts "\n#{client.name}:"
  puts "  API Key: #{client.api_key}"
  puts "  Email: #{client.email}"
  puts "  Rate Limit: #{client.rate_limit} requests"
end
puts "\n" + "=" * 80
