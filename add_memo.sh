#!/bin/bash
# Quick Memo Adding Script
# Usage: ./add_memo.sh

echo "╔══════════════════════════════╗"
echo "║    📝 Add New Memo           ║"
echo "╚══════════════════════════════╝"
echo ""

read -p "📌 Title (optional, press Enter to skip): " title

read -p "✏️  Content (required): " content
if [ -z "$content" ]; then
    echo "❌ Error: Content cannot be empty"
    exit 1
fi

echo ""
echo "🏷️  Select category:"
echo "  1) 📋 General"
echo "  2) ✅ Todo"
echo "  3) 💡 Idea"
echo "  4) 📖 Note"
read -p "Enter number [1-4, default 1]: " category_num

case $category_num in
    2) category="todo" ;;
    3) category="idea" ;;
    4) category="note" ;;
    *) category="general" ;;
esac

echo ""
echo "⭐ Select priority:"
echo "  1) 📌 Normal"
echo "  2) ⭐ Important"
echo "  3) 🔥 Urgent"
read -p "Enter number [1-3, default 1]: " priority_num

case $priority_num in
    2) priority="important" ;;
    3) priority="urgent" ;;
    *) priority="normal" ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 执行Ruby脚本
if [ -z "$title" ]; then
    ruby add_memo.rb "$content" "" "$category" "$priority"
else
    ruby add_memo.rb "$content" "$title" "$category" "$priority"
fi

echo ""
echo "💡 提示: 记得提交到Git仓库以同步到网站："
echo "   git add _data/memos.yml"
echo "   git commit -m \"Add new memo\""
echo "   git push"
