#!/usr/bin/env ruby
# Memo Management Script
# Usage: ruby add_memo.rb "content" [title] [category] [priority]

require 'yaml'
require 'time'

# Get parameters
content = ARGV[0]
title = ARGV[1] || nil
category = ARGV[2] || 'general'
priority = ARGV[3] || 'normal'

if content.nil? || content.empty?
  puts "Usage: ruby add_memo.rb \"content\" [title] [category] [priority]"
  puts "Category options: general, todo, idea, note"
  puts "Priority options: normal, important, urgent"
  exit 1
end

# Validate category and priority
valid_categories = ['general', 'todo', 'idea', 'note']
valid_priorities = ['normal', 'important', 'urgent']

unless valid_categories.include?(category)
  puts "Error: Invalid category. Options: #{valid_categories.join(', ')}"
  exit 1
end

unless valid_priorities.include?(priority)
  puts "Error: Invalid priority. Options: #{valid_priorities.join(', ')}"
  exit 1
end

# File path
memos_file = File.join(__dir__, '_data', 'memos.yml')

# Read existing memos
memos = []
if File.exist?(memos_file)
  file_content = File.read(memos_file)
  # If file only contains [] or is empty, initialize as empty array
  if file_content.strip == '[]' || file_content.strip.empty? || file_content.lines.all? { |line| line.start_with?('#') || line.strip.empty? }
    memos = []
  else
    memos = YAML.load_file(memos_file) || []
  end
end

# Generate new ID
new_id = memos.empty? ? 1 : (memos.map { |m| m['id'] }.max + 1)

# Create new memo
new_memo = {
  'id' => new_id,
  'content' => content,
  'category' => category,
  'priority' => priority,
  'date' => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
  'completed' => false
}

new_memo['title'] = title if title && !title.empty?

# Add to the beginning of the list
memos.unshift(new_memo)

# Save to file
File.open(memos_file, 'w') do |file|
  file.write("# Memo data file\n")
  file.write("# Supported fields: id, title(optional), content, category, priority, date, completed\n")
  file.write("# Categories: general, todo, idea, note\n")
  file.write("# Priorities: normal, important, urgent\n\n")
  file.write(memos.to_yaml)
end

# Display priority icon
priority_icon = case priority
when 'urgent' then '🔥'
when 'important' then '⭐'
else '📌'
end

puts "✅ Memo added successfully!"
puts "━━━━━━━━━━━━━━━━━━━━"
puts "ID: #{new_id}"
puts "Title: #{title || '(none)'}"
puts "Content: #{content}"
puts "Category: #{category}"
puts "Priority: #{priority_icon} #{priority}"
puts "Time: #{new_memo['date']}"
puts "━━━━━━━━━━━━━━━━━━━━"
