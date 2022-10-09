current_dir = File.expand_path(File.dirname(__FILE__))

log_level :debug
log_location "#{current_dir}/chef-solo.log"
checksum_path "#{current_dir}/checksums"
cookbook_path "#{current_dir}/cookbooks"
data_bag_path "#{current_dir}/data_bags"
environment_path "#{current_dir}/environments"
file_backup_path "#{current_dir}/backup"
file_cache_path "#{current_dir}/cache"
role_path "#{current_dir}/roles"
sandbox_path "#{current_dir}/sandbox"
syntax_check_cache_path "#{current_dir}/syntax_check_cache"
