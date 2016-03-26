require 'bundler'
require 'tempfile'
require "bundle_update_checker/version"

module BundleUpdateChecker
  class TryUpdate
    def command_exec(command)
      system "#{command} > /dev/null 2>&1"
      raise "#{command} - failed" unless $?.exitstatus==0
    end


    def fetch_version(gem, lockfile:'Gemfile.lock')
      re = Regexp.new("    #{gem}\s+\((.+)\)")
      File.open(lockfile).each_line{|line|
        m = line.match(re)
        return m[1] if m
      }
      nil
    end


    def try_update(*gems)
      gem_str = gems.join(' ')
      print "processing: #{gem_str} "

      FileUtils.cp("Gemfile.lock", @lock_backups[0])
      command_exec "bundle clean"
      FileUtils.cp("Gemfile.lock", @lock_backups[1])
      command_exec "bundle update #{gem_str}"
      if `diff #{@lock_backups[1]} Gemfile.lock|wc -l`.to_i == 0
        puts "(skipped)"
        return nil
      end

      begin
        result = IO.popen(@test_command){|io|
          while line = io.gets
          end
          io.close
          $?.exitstatus
        }
        if gems.size==1
          ver_from = fetch_version(gem_str, lockfile:@lock_backups[1])
          ver_to   = fetch_version(gem_str)
          result = [result, "#{ver_from}=>#{ver_to}"]
        else
          result = [result]
        end
      ensure
        FileUtils.cp(@lock_backups[0], "Gemfile.lock")
        command_exec "bundle clean"
      end
      p(result)
      result
    end


    def try_all
      depends = Bundler::Definition.build('Gemfile', nil, nil).dependencies
      default_gems = depends.select{|g| g.groups.include? @group}.map{|g| g.name}
      update_result = default_gems.inject({}){|s, v|
        r = try_update(v)
        s[v] = r
        s
      }
      succeed_gems = update_result.select{|k,v| v and v[0]==0}.keys
      if succeed_gems.size>1
        update_result['_combine_'] = [try_update(succeed_gems)[0], succeed_gems.join(' ')]
      else
        update_result['_combine_'] = [nil]
      end
      update_result
    end


    def initialize(test_command, group:nil)
      raise ArgumentError, "test_command required" unless test_command
      @group = (group || 'default').to_sym
      @test_command = test_command
      @tempfiles = [Tempfile.new("Gemfile-lock"), Tempfile.new("Gemfile-lock")]
      @lock_backups = @tempfiles.map{|t| t.close; t.path}
      command_exec test_command
    end
  end
end
