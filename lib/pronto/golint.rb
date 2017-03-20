require 'pronto'
require 'open3'
require 'shellwords'
require 'json'

module Pronto
  class Golint < Runner
    def initialize(patches, commit = nil)
      super
      @executable = ENV['PRONTO_GOLINT_EXECUTABLE'] || 'golint'
    end

    def run
      return [] unless @patches

      @patches.select { |patch| valid_patch?(patch) }
        .map { |patch| inspect(patch) }
        .flatten.compact
    end

    def valid_patch?(patch)
      patch.additions > 0 && go_file?(patch.new_file_full_path)
    end

    def inspect(patch)
      escaped_executable = Shellwords.escape(@executable)
      escaped_path = Shellwords.escape(patch.new_file_full_path.to_s)

      Open3.popen3(`#{escaped_executable} #{escaped_path}`) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets
          file_path, line_number, severity, message = line.split(':')
          Message.new(file_path, line_number, severity, message, nil, self.class)
        end
      end
    end

    def go_file?(path)
      File.extname(path) == '.go'
    end
  end
end
