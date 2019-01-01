require 'test_helper'
require 'uri'
require 'rake'
load File.expand_path('lib/tasks/test/teardown.rake')

class ExternalDnsComponentTest < Test
  TIMEOUT_FOR_EXTERNAL_DNS = 123 # External DNS can take up to two minutes (give it an extra 3 seconds)
  SLEEP_INTERVAL           = 3 # wait 3 seconds between polls
  MAX_ATTEMPTS             = TIMEOUT_FOR_EXTERNAL_DNS / SLEEP_INTERVAL

  def test_pod_running
    assert_pod_running 'external-dns'
  end

  def test_it_creates_route53_record
    apply_manifest
    wait_for_deployment

    begin
      assert record_exists_in_route53?
    ensure
      Rake::Task['clean_up_route53'].invoke
    end
  end

  private

  def apply_manifest
    `kubectl apply -f #{manifest}`
  end

  def deployment
    YAML.load_stream(File.read(manifest))
      .find { |manifest| manifest.dig('kind') == 'Deployment' }
      .dig('metadata', 'name')
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

  def manifest
    File.join(__dir__, 'fixtures', 'test_app.yml')
  end

  def record_exists_in_route53?(attempt = 0)
    return true if poll_route53.size == 1
    return false if attempt == MAX_ATTEMPTS

    attempt += 1
    sleep SLEEP_INTERVAL
    record_exists_in_route53?(attempt)
  end

  def poll_route53
    zone           = hostname.split('.').drop(1).join('.')
    hosted_zone_id = hosted_zone_id(zone)

    JSON.parse(`aws route53 list-resource-record-sets --hosted-zone-id #{hosted_zone_id} --query "ResourceRecordSets[?Name == '#{hostname}.']"`.chomp)
      .select { |record| record.dig('Type') == 'A' }

  end

  def wait_for_deployment
    `kubectl rollout status deployment/#{deployment}`
  end

end
