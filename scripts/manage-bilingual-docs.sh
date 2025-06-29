#!/bin/bash

# 🌐 Bilingual Documentation Manager for CardManager
# Manage French and US versions of documentation

echo "🌐 CardManager Bilingual Documentation Manager"
echo "============================================="

show_help() {
    echo ""
    echo "📚 Available commands:"
    echo "  sync-to-us      - Copy French content to US versions"
    echo "  sync-to-fr      - Copy US content to French versions"
    echo "  list-docs       - List all documentation files"
    echo "  check-sync      - Check synchronization status"
    echo "  help            - Show this help"
    echo ""
}

list_docs() {
    echo "📄 French Documentation:"
    ls -la *.md | grep -v "\-us\.md"
    echo ""
    echo "🇺🇸 US Documentation:"
    ls -la *-us.md 2>/dev/null || echo "No US documentation found"
}

check_sync() {
    echo "🔍 Checking documentation synchronization..."
    echo ""

    for fr_file in *.md; do
        if [[ "$fr_file" != *"-us.md" ]]; then
            us_file="${fr_file%.md}-us.md"
            if [ -f "$us_file" ]; then
                fr_size=$(stat -c%s "$fr_file" 2>/dev/null || stat -f%z "$fr_file" 2>/dev/null)
                us_size=$(stat -c%s "$us_file" 2>/dev/null || stat -f%z "$us_file" 2>/dev/null)

                if [ "$fr_size" -eq "$us_size" ]; then
                    echo "✅ $fr_file ↔ $us_file (same size)"
                else
                    echo "⚠️  $fr_file ↔ $us_file (different sizes: $fr_size vs $us_size)"
                fi
            else
                echo "❌ $fr_file → Missing $us_file"
            fi
        fi
    done
}

# Main script logic
case "$1" in
    "list-docs"|"list")
        list_docs
        ;;
    "check-sync"|"check")
        check_sync
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac
