#!/usr/bin/env ruby
# Memo Sync Script for Jekyll GitHub Pages
# Usage: ruby sync_memo.rb < memo.json

require 'yaml'
require 'json'
require 'fileutils'
require 'base64'

class MemoSync
  DATA_FILE = '_data/memos.yml'
  IMAGES_DIR = 'assets/images/memos'
  FILES_DIR = 'assets/files/memos'
  MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB per file (conservative limit)

  def initialize
    FileUtils.mkdir_p(IMAGES_DIR)
    FileUtils.mkdir_p(FILES_DIR)
  end

  # Sync memo from JSON input
  def sync_from_json(json_input)
    begin
      memo_data = JSON.parse(json_input)
      
      # Only sync public memos
      if memo_data['visibility'] == 'private'
        puts "⚠️  Skipping private memo - will stay local only"
        return false
      end
      
      # Process attachments
      if memo_data['images']
        memo_data['images'] = process_images(memo_data['images'], memo_data['id'])
      end
      
      if memo_data['files']
        memo_data['files'] = process_files(memo_data['files'], memo_data['id'])
      end
      
      # Remove base64 data fields (keep URLs only)
      memo_data.delete('images_data')
      memo_data.delete('files_data')
      
      # Load existing memos
      memos = load_memos
      
      # Add or update memo
      existing_index = memos.find_index { |m| m['id'] == memo_data['id'] }
      if existing_index
        memos[existing_index] = memo_data
        puts "📝 Updated existing memo"
      else
        memos.unshift(memo_data)
        puts "✅ Added new memo"
      end
      
      # Save to YAML
      save_memos(memos)
      
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts "✓ Memo synced successfully!"
      puts "  ID: #{memo_data['id']}"
      puts "  Title: #{memo_data['title'] || '(none)'}"
      puts "  Visibility: #{memo_data['visibility'] || 'public'}"
      puts "  Images: #{memo_data['images']&.length || 0}"
      puts "  Files: #{memo_data['files']&.length || 0}"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      puts ""
      puts "Next steps:"
      puts "  git add _data/memos.yml #{IMAGES_DIR}/ #{FILES_DIR}/"
      puts "  git commit -m \"Add memo: #{memo_data['title'] || 'Untitled'}\""
      puts "  git push"
      
      true
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      false
    end
  end

  # Delete memo
  def delete_memo(memo_id)
    memos = load_memos
    memo = memos.find { |m| m['id'] == memo_id.to_i }
    
    if memo
      # Delete attachments
      delete_attachments(memo)
      
      # Remove from list
      memos.reject! { |m| m['id'] == memo_id.to_i }
      save_memos(memos)
      
      puts "✓ Memo deleted successfully!"
      puts "Remember to commit: git add -A && git commit -m 'Delete memo' && git push"
      true
    else
      puts "✗ Memo not found"
      false
    end
  end

  private

  def load_memos
    if File.exist?(DATA_FILE)
      content = File.read(DATA_FILE)
      # Handle empty or comment-only files
      if content.strip.empty? || content.strip == '[]' || content.lines.all? { |l| l.strip.start_with?('#') || l.strip.empty? }
        []
      else
        YAML.load_file(DATA_FILE) || []
      end
    else
      []
    end
  end

  def save_memos(memos)
    File.open(DATA_FILE, 'w') do |file|
      file.write("# Public Memos - Synced from website\n")
      file.write("# Generated: #{Time.now}\n\n")
      file.write(memos.to_yaml)
    end
  end

  def process_images(images, memo_id)
    images.map.with_index do |img_data, index|
      if img_data.is_a?(String) && img_data.start_with?('data:image')
        save_base64_image(img_data, memo_id, index)
      else
        img_data
      end
    end.compact
  end

  def process_files(files, memo_id)
    files.map.with_index do |file, index|
      file_data = file.is_a?(Hash) ? file['data'] : file
      
      if file_data.to_s.start_with?('data:')
        saved_url = save_base64_file(file_data, memo_id, file['name'])
        if saved_url
          {
            'name' => file['name'],
            'url' => saved_url,
            'size' => file['size']
          }
        else
          nil
        end
      else
        file
      end
    end.compact
  end

  def save_base64_image(base64_data, memo_id, index)
    # Extract image type and data
    match = base64_data.match(/data:image\/(\w+);base64,(.+)/)
    unless match
      puts "⚠️  Invalid image format, skipping..."
      return nil
    end
    
    ext = match[1]
    data = match[2]
    
    # Check size
    decoded = Base64.decode64(data)
    if decoded.bytesize > MAX_FILE_SIZE
      puts "⚠️  Image too large (#{format_size(decoded.bytesize)}), skipping... (max #{format_size(MAX_FILE_SIZE)})"
      return nil
    end
    
    filename = "#{memo_id}_#{index}.#{ext}"
    filepath = File.join(IMAGES_DIR, filename)
    
    File.open(filepath, 'wb') do |f|
      f.write(decoded)
    end
    
    puts "  📷 Saved image: #{filename} (#{format_size(decoded.bytesize)})"
    "/#{filepath}"
  end

  def save_base64_file(base64_data, memo_id, original_name)
    # Extract file type and data
    match = base64_data.match(/data:([^;]+);base64,(.+)/)
    unless match
      puts "⚠️  Invalid file format, skipping..."
      return nil
    end
    
    data = match[2]
    
    # Check size
    decoded = Base64.decode64(data)
    if decoded.bytesize > MAX_FILE_SIZE
      puts "⚠️  File too large (#{format_size(decoded.bytesize)}), skipping... (max #{format_size(MAX_FILE_SIZE)})"
      return nil
    end
    
    ext = File.extname(original_name)
    safe_name = original_name.gsub(/[^a-zA-Z0-9._-]/, '_')
    
    filename = "#{memo_id}_#{safe_name}"
    filepath = File.join(FILES_DIR, filename)
    
    File.open(filepath, 'wb') do |f|
      f.write(decoded)
    end
    
    puts "  📎 Saved file: #{filename} (#{format_size(decoded.bytesize)})"
    "/#{filepath}"
  end

  def delete_attachments(memo)
    # Delete images
    if memo['images']
      memo['images'].each do |img_path|
        filepath = img_path.sub(/^\//, '')
        if File.exist?(filepath)
          File.delete(filepath)
          puts "  🗑️  Deleted: #{filepath}"
        end
      end
    end
    
    # Delete files
    if memo['files']
      memo['files'].each do |file|
        filepath = file['url'].sub(/^\//, '')
        if File.exist?(filepath)
          File.delete(filepath)
          puts "  🗑️  Deleted: #{filepath}"
        end
      end
    end
  end

  def format_size(bytes)
    if bytes < 1024
      "#{bytes} B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(2)} KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(2)} MB"
    end
  end
end

# CLI usage
if __FILE__ == $0
  sync = MemoSync.new
  
  case ARGV[0]
  when 'sync'
    # Read JSON from stdin
    json_input = STDIN.read
    success = sync.sync_from_json(json_input)
    exit(success ? 0 : 1)
  when 'delete'
    memo_id = ARGV[1]
    if memo_id
      success = sync.delete_memo(memo_id)
      exit(success ? 0 : 1)
    else
      puts "Usage: ruby sync_memo.rb delete <memo_id>"
      exit(1)
    end
  else
    puts "Memo Sync Tool for Jekyll GitHub Pages"
    puts ""
    puts "Usage:"
    puts "  ruby sync_memo.rb sync < memo.json"
    puts "  ruby sync_memo.rb delete <memo_id>"
    puts ""
    puts "Limitations:"
    puts "  - Only PUBLIC memos are synced to server"
    puts "  - Private memos stay in your browser only"
    puts "  - Max file size: 10MB per attachment"
    puts "  - Recommended total repo size: < 1GB"
    exit(1)
  end
end
