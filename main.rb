require 'optparse'
require 'ripper'
require 'fileutils'

module RubyFormatter
  class Parser
    def initialize(source)
      @source = source
      @tokens = []
    end

    def parse
      sexp = Ripper.sexp(@source)
      @tokens = tokenize(@source)
      { sexp: sexp, tokens: @tokens }
    end

    private

    def tokenize(source)
      Ripper.lex(source)
    end
  end

  class Formatter
    def initialize(options = {})
      @option = {
        indent_size: options.fetch(:indent_size, 2),
        max_line_length: options.fetch(:max_line_length, 80),
        trailing_comma: options.fetch(:trailing_comma, false)
      }.merge(options)
    end

    def format(source)
      parser = Parser.new(source)
      parsed = parser.parse
      format_source(parsed)
    end

    def format_source(source)
      lines = source.split("\n")
      formatted_lines = []
      
      current_indent = 0
      indent_unit = " " * @options[:indent_size]
      
      lines.each do |line|
        # インデントを減らす必要がある行を検出
        if line.strip =~ /^end$|^else$|^elsif.*$|^rescue.*$|^ensure$|^when.*$/
          current_indent -= 1 unless current_indent.zero?
        end
        
        # 行をトリムしてインデントを適用
        formatted_line = indent_unit * current_indent + line.strip
        
        # 必要に応じて行の長さを調整
        if formatted_line.length > @options[:max_line_length]
          # ここで長い行の折り返し処理を実装
        end
        
        formatted_lines << formatted_line
        
        # インデントを増やす必要がある行を検出
        if line =~ /(\s|^)(if|unless|def|class|module|begin|case|while|until|for|do)(\s|\(|$)/
          current_indent += 1
        end
      end
    end
  end

  class CLI
    def initialize(args)
      @args = args
      @options = {
        write: false,
        check: false,
        indent_size: 2,
        max_line_length: 80
      }
  
      @files = []
    end
  
    def run
      parse_options
      if @args.empty?
        puts "No files specified."
        exit 1
      end

      @args.each do |file|
        process_file(file)
      end
    end
  
    private
  
    def parse_options
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: ruby-formatter [options] [file ...]"
        
        opts.on("-w", "--write", "Write formatted code back to file") do
          @options[:write] = true
        end
        
        opts.on("-c", "--check", "Check if files are formatted without modifying them") do
          @options[:check] = true
        end
        
        opts.on("--indent-size SIZE", Integer, "Indent size (default: 2)") do |size|
          @options[:indent_size] = size
        end
        
        opts.on("--max-line-length LENGTH", Integer, "Maximum line length (default: 80)") do |length|
          @options[:max_line_length] = length
        end
        
        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit
        end
      end
  
      begin
        opt_parser.parse!(@args)
      rescue OptionParser::InvalidOption => e
        puts e.message
        puts opt_parser
        exit 1
      end
    end
  
    def process_file(file)
      begin
        source = File.read(file)
        formatter = Formatter.new(@options)
        formatted = formatter.format(source)
        
        if @options[:check]
          if source != formatted
            puts "#{file}: Would reformat"
            exit 1
          else
            puts "#{file}: Looks good!"
          end
        elsif @options[:write]
          if source != formatted
            File.write(file, formatted)
            puts "#{file}: Reformatted"
          else
            puts "#{file}: Already formatted"
          end
        else
          puts formatted
        end
      rescue => e
        puts "Error processing #{file}: #{e.message}"
        exit 1
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  puts "Ruby Formatter"
  RubyFormatter::CLI.new(ARGV).run
end
