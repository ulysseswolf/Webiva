
$KCODE='u'

AUTHORIZATION_MIXIN = "object roles"
DEFAULT_REDIRECTION_HASH = { :controller => '/manage/access', :action => 'denied' }

# Be sure to restart your web server when you modify this file.


# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production' 
ENV['HOME'] ||= '/home/webiva'


# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2'

# Concurrency required from backgroundrb,
# But required to not be on for 
#if ENV['RAILS_ENV'] == 'backgroundrb' ||  ENV['RAILS_ENV'] == 'backgroundrb_development'
#  ActiveRecord::Base.allow_concurrency = true
#  raise 'AllowingConcurreny!!'
#else
#  ActiveRecord::Base.allow_concurrency = false
#end


require 'yaml'

# Set up some constants
  defaults_config_file = YAML.load_file(File.join(File.dirname(__FILE__), "defaults.yml"))
  
  WEBIVA_LOGO_FILE = defaults_config_file['logo_override'] || nil 

  CMS_DEFAULT_LANGUAGE = defaults_config_file['default_language'] || 'en'
  CMS_DEFAULT_CONTRY = defaults_config_file['default_country'] || 'US'
  CMS_CACHE_ACTIVE = defaults_config_file['active_cache'] || true
  CMS_DEFAULT_DOMAIN = defaults_config_file['domain']
  
  CMS_SYSTEM_ADMIN_EMAIL = defaults_config_file['system_admin']
  
  DEFAULT_DATETIME_FORMAT = defaults_config_file['default_datetime_format'] || "%m/%d/%Y %I:%M %p"
  DEFAULT_DATE_FORMAT = defaults_config_file['default_date_format'] || "%m/%d/%Y"
  
  BETA_CODE = defaults_config_file['enable_beta_code'] || false
  
  USE_X_SEND_FILE = defaults_config_file['use_x_send_file'] || false
 
  GIT_REPOSITORY = defaults_config_file['git_repository'] || nil 



#RAILS_ROOT = File.dirname(__FILE__) + "../" unless defined?(RAILS_ROOT)

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|


  config.database_configuration_file = "#{RAILS_ROOT}/config/cms.yml"
  config.action_controller.session_store = :mem_cache_store
  config.plugin_paths = ["#{RAILS_ROOT}/vendor/plugins", "#{RAILS_ROOT}/vendor/modules" ]
  
 # config.time_zone = 'UTC'
  
 #config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
 #  File.directory?(lib = "#{dir}/lib") ? lib : dir
 #end
  
  config.gem 'mysql'
  config.gem 'mime-types', :lib => 'mime/types'
  config.gem 'radius'
  config.gem 'RedCloth', :lib => 'redcloth'
  config.gem 'BlueCloth', :lib => 'bluecloth'
  config.gem 'gruff'
  config.gem 'slave'
  config.gem 'hpricot'
  config.gem 'daemons'
  config.gem 'maruku'
  config.gem 'net-ssh', :lib => 'net/ssh'
  config.gem 'rmagick', :lib => 'RMagick'
  config.gem 'libxml-ruby', :lib => 'xml'
  config.gem 'soap4r', :lib => 'soap/soap'
  config.gem "rspec", :lib => false, :version => ">= 1.2.0"
  config.gem "rspec-rails", :lib => false, :version => ">= 1.2.0"
  config.gem "json"
  config.gem "system_timer"

  if CMS_CACHE_ACTIVE
    config.gem 'memcache-client', :lib => 'memcache'
  end
end


ActionMailer::Base.logger = nil unless RAILS_ENV == 'development'

# Copy Assets over

Dir.glob("#{RAILS_ROOT}/vendor/modules/[a-z]*") do |file|
  if file =~ /\/([a-z_-]+)\/{0,1}$/
    mod_name = $1
    if File.directory?(file + "/public")
      FileUtils.mkpath("#{RAILS_ROOT}/public/components/#{mod_name}")
      FileUtils.cp_r(Dir.glob(file + "/public/*"),"#{RAILS_ROOT}/public/components/#{mod_name}/")
    end
  end
end


ActionMailer::Base.logger = nil unless ENV['RAILS_ENV'] == 'development'


if RAILS_ENV == 'test'
    if defaults_config_file['testing_domain']
      SystemModel.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")[:test])
      DomainModel.activate_domain(Domain.find(defaults_config_file['testing_domain']).attributes,'production',false)
    else
      raise 'No Available Testing Database!'
    end
end 


module Globalize
  class ModelTranslation
    def self.connection
      DomainModel.connection
    end
  end
end

Globalize::ModelTranslation.set_table_name('globalize_translations')

  
  memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => 'Webiva',
    :readonly => false,
    :urlencode => false
  }
  
  CACHE = MemCache.new memcache_options
  CACHE.servers =  [ 'localhost:11211' ]
  ActionController::Base.session_options[:cache] = CACHE


# Globalize Setup
include Globalize

# Load up some monkey patches
# For: Globalize and Date and Time classes
require 'webiva_monkey_patches'

# Base Language is always en-US - Language application was written in
Locale.set_base_language('en-US')

gem 'soap4r'

