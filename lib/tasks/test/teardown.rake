require 'tempfile'
require 'json'
require 'open3'
require 'yaml'

desc 'Teardown the test cluster'
task :teardown do
  delete_cluster
  Rake::Task['clean_up_route53'].invoke
end

desc 'Clean-up the E2E Route53 record'
task :clean_up_route53 do
  clean_up_route53_records
end

private

def delete_cluster
  puts "Tearing down cluster"
  teardown_command = 'bin/eks-box -o delete -c config.yml'
  Open3.popen2e(teardown_command) do |_, stdout_stderr, wait_thread|
    while (line = stdout_stderr.gets) do
      puts line
    end

    wait_thread.value
  end
end

def delete_record(zone_id, record)
  changeset = {
    'Changes': [
                 {
                   'Action':            'DELETE',
                   'ResourceRecordSet': record
                 }
               ]
  }.to_json

  Tempfile.open('eks-in-a-box-teardown') do |file|
    file.write(changeset)
    file.flush

    cmd = "aws route53 change-resource-record-sets --hosted-zone-id=#{zone_id} --change-batch file://#{file.path}"
    puts "Executing '#{cmd}'" if ENV['DEBUG']
    `#{cmd}`
  end
end

def manifest
  File.join(ROOT, 'test', 'fixtures', 'test_app.yml')
end

def hostname
  YAML.load_stream(File.read(manifest))
    .find { |f| f.dig('kind') == 'Ingress' }
    .dig('spec', 'rules')
    .first
    .dig('host')
end

def hosted_zone_id(zone)
  JSON.parse(`aws route53 list-hosted-zones`.chomp)
    .dig('HostedZones')
    .find { |hosted_zone| hosted_zone.dig('Name').chop == zone }
    .dig('Id')
end

def clean_up_route53_records
  zone           = hostname.split('.').drop(1).join('.')
  hosted_zone_id = hosted_zone_id(zone)
  records        = JSON.parse(`aws route53 list-resource-record-sets --hosted-zone-id #{hosted_zone_id} --query "ResourceRecordSets[?Name == '#{hostname}.']"`.chomp)

  records.map { |record| delete_record(hosted_zone_id, record) }
end
