module Elasticity

  class HiveStep

    include Elasticity::JobFlowStep

    attr_accessor :name
    attr_accessor :script
    attr_accessor :variables
    attr_accessor :action_on_failure
    attr_accessor :version

    def initialize(script)
      @name = "Elasticity Hive Step (#{script})"
      @script = script
      @variables = {}
      @action_on_failure = 'TERMINATE_JOB_FLOW'
      @version = 'latest'
    end

    def to_aws_step(_)
      args = %W(
        s3://elasticmapreduce/libs/hive/hive-script 
        --base-path s3://elasticmapreduce/libs/hive/ 
        --hive-versions #{version} 
        --run-hive-script 
        --args
        -f #{@script}
      )
      @variables.keys.sort.each do |name|
        args.concat(['-d', "#{name}=#{@variables[name]}"])
      end
      {
        :name => @name,
        :action_on_failure => @action_on_failure,
        :hadoop_jar_step => {
          :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => args
        }
      }
    end

    def self.requires_installation?
      true
    end

    def self.aws_installation_step_name
      'Elasticity - Install Hive'
    end

    def self.aws_installation_steps(version='latest')
      steps = [
        {
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
            :args => "s3://elasticmapreduce/libs/hive/hive-script --base-path s3://elasticmapreduce/libs/hive/ --install-hive --hive-versions #{version}"
          },
          :name => aws_installation_step_name
        }
      ]
      if Elasticity.configuration.hive_site
        steps << {
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
            :args => [
              's3://elasticmapreduce/libs/hive/hive-script',
              '--base-path',
              's3://elasticmapreduce/libs/hive/',
              '--install-hive-site',
              "--hive-site=#{Elasticity.configuration.hive_site}",
              '--hive-versions',
              version
            ],
          },
          :name => 'Elasticity - Configure Hive via Hive Site'
        }
      end
      steps
    end

  end

end