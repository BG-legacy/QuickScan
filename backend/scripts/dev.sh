#!/bin/bash

# QuickScan Backend Development Script

echo "🚀 Starting QuickScan Backend Development Server..."
echo "📍 Server will be available at: http://127.0.0.1:3000"
echo "📖 API Documentation available in README.md"
echo ""

# Set development environment variables
export RUST_LOG=quickscan_backend=debug,tower_http=debug

# Start the server with cargo watch for hot reload if available
if command -v cargo-watch &> /dev/null; then
    echo "🔄 Using cargo-watch for hot reload..."
    cargo watch -x run
else
    echo "💡 Install cargo-watch for hot reload: cargo install cargo-watch"
    echo "▶️  Starting server..."
    cargo run
fi 