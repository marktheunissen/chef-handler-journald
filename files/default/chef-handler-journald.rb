require 'chef'
require 'chef/handler'
require 'systemd/journal'

class JournaldHandler < Chef::Handler
  attr_writer :syslog_identifier, :fail_priority, :success_priority, :log_success

  def initialize(options = {})
    @syslog_id = options[:syslog_identifier]
    @fpriority = options[:fail_priority]
    @spriority = options[:success_priority]
    @log_success = options[:log_success]
  end

  def report
    if run_status.success? && !@log_success
      Chef::Log.debug('Journald handler: Chef run succeeded. Not logging to the journal because `log_success = false`')
      return
    end

    log_entry = {
      'PRIORITY' => run_status.success? ? @spriority : @fpriority,
      'SYSLOG_IDENTIFIER' => @syslog_id,
      'MESSAGE' => run_status.success? ? 'Chef run succeeded.' : 'Chef run failed.',
      'CHEF_RUN_STATUS' => run_status.success? ? 'success' : 'failure',
    }
    log_entry['CHEF_EXCEPTION'] = run_status.formatted_exception if run_status.formatted_exception
    log_entry['CHEF_EXCEPTION_CLASS'] = run_status.exception.class if run_status.exception

    if run_status.node['chef_client']['handler']['journald'].attribute?('custom_fields')
      run_status.node['chef_client']['handler']['journald']['custom_fields'].each do | key, value |
        if !value.nil? && !value.to_s.empty?
          log_entry[key.upcase] = value.to_s
        end
      end
    end

    Chef::Log.debug("Logging to the journal: #{log_entry}")
    begin
      Systemd::Journal.message(log_entry)
    rescue => e
      Chef::Log.error("Error logging to the systemd journal: #{e}")
    end
  end

end
