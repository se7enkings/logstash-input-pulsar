Gem::Specification.new do |s|
    s.name            = 'logstash-input-pulsar'
    s.version         = '2.11.0.2'
    s.licenses        = ['Apache-2.0']
    s.summary         = 'This input will read events from a pulsar topic.'
    s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
    s.authors         = ['ShiyiLiang', 'Tianyue Ren']
    s.email           = 'rentianyue-jk@360shuke.com'
    s.homepage        = "https://github.com/NiuBlibing/logstash-input-pulsar"
    s.require_paths = ['lib']
  
    # Files
    s.files = Dir["lib/**/*","spec/**/*","*.gemspec","*.md","CONTRIBUTORS","Gemfile","LICENSE","NOTICE.TXT", "vendor/jar-dependencies/**/*.jar", "vendor/jar-dependencies/**/*.rb", "VERSION", "docs/**/*"]
  
    # Tests
    #s.test_files = s.files.grep(%r{^(test|spec|features)/})
  
    # Special flag to let us know this is actually a logstash plugin
    s.metadata = { 'logstash_plugin' => 'true', 'group' => 'input'}
  
    s.requirements << "jar 'org.apache.pulsar:pulsar-client', '2.11.0'"
    s.requirements << "jar 'org.slf4j:slf4j-log4j12', '1.7.32'"
    s.requirements << "jar 'org.apache.logging.log4j:log4j-1.2-api', '2.18.0'"
  
    s.add_development_dependency 'jar-dependencies', '~> 0.3.2'
  
    # Gem dependencies
    s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"
    s.add_runtime_dependency 'logstash-codec-json'
    s.add_runtime_dependency 'logstash-codec-plain'
    s.add_runtime_dependency 'stud', '>= 0.0.22', '< 0.1.0'
  
    s.add_development_dependency 'logstash-devutils'
    s.add_development_dependency 'rspec-wait'
  end