Chef Journald Handler
---------------------

Handler that logs an entry to the systemd journal with the run status, exception details, configurable priority and any custom fields that you require. For example, you could log an entry like the following when a Chef run fails:

```json
{
  "PRIORITY": "3",
  "ENVIRONMENT": "env",
  "BINDING_ID": "xyz",
  "SYSLOG_IDENTIFIER": "chef",
  "MESSAGE": "Chef run failed.",
  "CHEF_RUN_STATUS": "failure",
  "CHEF_EXCEPTION": "RuntimeError: ruby_block[](line 371) had an error: RuntimeError: Converge failure.",
  "CHEF_EXCEPTION_CLASS": "RuntimeError",
  "SITE_ID": "xyz",
  "SITE_NAME": "mysite",
  "BUILD_URL": "https://localhost:8090/build12345",
  "BUILD_NUMBER": "123456",
  "BUILD_ID": "2014-10-30_11-12-23"
}
```

Requirements
------------

The Ruby gem [systemd-journal](https://github.com/ledbettj/systemd-journal), which is installed by the recipe.

Usage
-----

Just include the handler very early (if not first) in your node's run_list:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[journald-handler]"
  ]
}
```

Or from another recipe, you can use an include:

```ruby
include_recipe 'journald-handler'
```

By default, after each Chef run a log entry is made with priority LOG_ERR for exceptions, and LOG_INFO for success. You can change the priorities, or turn off logging for successful runs, using attributes on the node. For example, do this before your include_recipe:

```ruby
node.override['chef_client']['handler']['journald']['log_success'] = false
node.override['chef_client']['handler']['journald']['success_priority'] = Systemd::Journal::LOG_WARN
include_recipe 'journald-handler'
```

To add custom fields to your log entries from a recipe, do this:

```ruby
# Set some custom fields that will be added to the log entry for context.
node.set['chef_client']['handler']['journald']['custom_fields'] = {
  'endpoint_id' => endpoint_uuid(),
  'build_url' => ENV['BUILD_URL'],
  'build_number' => ENV['BUILD_NUMBER'],
  'build_id' => ENV['BUILD_ID'],
  'syslog_identifier' => ENV['JOB_NAME'],
}
```

You can append extra fields using a merge:

```ruby
node.set['chef_client']['handler']['journald']['custom_fields'] = node['chef_client']['handler']['journald']['custom_fields'].merge(
  'environment' => metadata['environment'],
  'site_id' => metadata['site'],
  'site_name' => metadata['name'],
)
```

All field names will be uppercased, and any that you set in a recipe will override the defaults (e.g. syslog_identifier).

License
-------

MIT (EXPAT)
