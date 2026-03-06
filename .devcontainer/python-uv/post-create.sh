#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Verify key CLIs are available (all installed via Dockerfile)
echo "✅ CLIs available:"
for cli in nvim opencode uv starship zoxide; do
  which "$cli" 2>/dev/null && echo "  ✅ $cli: $(which $cli)" || echo "  ⚠️  $cli: missing"
done

echo "✅ Post-create complete. Run 'nvim .' or 'tdl opencode' to get started."
