
# ------------------------------------------------------------------------
# Class MsBuilder
# ------------------------------------------------------------------------

class MsBuilder
    # Show only errors
    attr_accessor :show_error_only
    
    # Show error and warning summary at the end
    attr_accessor :show_summary
    
    # Show time spent in tasks, targets and projects
    attr_accessor :show_performance_summary

    # Specifies the maximum number of concurrent processes to build with.
    attr_accessor :max_cpu_count
    
    # Set or override these project-level properties. e.g. /property:WarningLevel=2;OutDir=bin\Debug\
    attr_accessor :properties
    
    # Build these targets in this project. e.g. /target:Resources;Compile
    attr_accessor :build_target
        
    def initialize
        @show_error_only = true
        @show_summary = true
        @show_performance_summary = false
        @max_cpu_count = 4
        @build_target = 'Rebuild'
        @configuration = 'Debug'
        @properties = { }
    end
    
    def build(sln)
        # set console logger options
        consoleloggerparameters = []
        consoleloggerparameters.push('Summary') if @show_summary
        consoleloggerparameters.push('ErrorsOnly') if @show_error_only
        consoleloggerparameters.push('PerformanceSummary') if @show_performance_summary
        consolelogger_opt = consoleloggerparameters.join(';')

        # set property options
        property_opt = []
        
        # set configuration: Debug / Release
        property_opt.push("Configuration=#{@configuration}")

        # set user properties
        if @properties != nil
            @properties.each { |k, v|
                property_opt.push("#{k}=#{v}")
            }
        end
        
        if File.exist?(sln)
            cmd = "MSBuild.exe \"#{sln}\" /nologo /m:#{max_cpu_count} /t:#{build_target} /p:#{property_opt.join(';')} /consoleloggerparameters:#{consolelogger_opt}"
            puts cmd
            system(cmd)
            return ($? == 0)
        else
            puts "*** Not found solution: #{sln}"
            return false
        end
    end
end

# ------------------------------------------------------------------------
# Class DeploymentRule
# ------------------------------------------------------------------------

class DeploymentRule
    # Destination path(s) to deploy, it can be a string or an array of string
    attr_reader :dest_path
    
    # Pattern to match the rule
    attr_reader :pattern
    
    def initialize(pattern, dest_path)
        @pattern = pattern
        @dest_path = dest_path
        @regexp = Regexp.new(pattern, Regexp::EXTENDED | Regexp::IGNORECASE)
    end
    
    def match?(filename)
        name = File.basename(filename)
        md = @regexp.match(name)
        return md != nil
    end
    
    def to_s()
        return "(dest path = #{dest_path}, pattern = #{pattern})"
    end
end

# ------------------------------------------------------------------------
# Class Deployment
# ------------------------------------------------------------------------

class Deployment
    def self.deploy_files(files, rules)
        if files.size > 0
            files.each {|filename|
                rules.each {|rule|
                    if rule.match?(File.basename(filename))
                        if rule.dest_path.is_a?(Array)
                            arr = rule.dest_path
                        else
                            arr = [rule.dest_path]
                        end
                        
                        arr.each {|path|
                            path = File.ospath(path)
                            if not Dir.exist?(path)
                                puts "  * Create directory for deployement: #{path}"
                                FileUtils.mkdir_p(path)
                            end
                            puts "  Copying #{File.basename(filename)} to #{path}..."
                            FileUtils.cp(filename, path)
                        }
                    end
                }
            }
        end
    end
end

