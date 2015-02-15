#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'json'
require 'csv'

# Option defaults
options = {
  "toggl_email"       => "you@example.com",
  "start_annotation"  => "Started task",
  "stop_annotation"   => "Stopped task",
  "export_cmd"        => "task export",
  "field_map"         => {
    "Project" => "description",
    "Tags"    => "project"
  }
}

# Read config file if available
config_path = File.join(ENV['HOME'],'.task-toggl.yml')
if File.exist?(config_path) then
  options.merge!(YAML.load_file(config_path))
end

# Process arguments
OptionParser.new do |opts|
    opts.banner = "Usage: task-toggl.rb [options]"

    opts.separator ""
    opts.separator "Options:"

    opts.on('-e', '--email [EMAIL]', 
            'Toggl user email address') do |val|
      options["toggl_email"] = val
    end

    opts.on('-s', '--start_annotation [TEXT]', 
            'Start annotation.  Default "Started task"') do |val|
      options["start_annotation"] = val
    end

    opts.on('-z', '--stop_annotation [TEXT]', 
            'Stop annotation.  Default "Stopped task"') do |val|
      options["stop_annotation"] = val
    end

    opts.on('-x', '--export-cmd [CMD]',
            'Command used to export task data.  Default "task export"') do |val|
      options["export_cmd"] = val
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
end.parse!


# Return HH:MM:SS difference between two Time objs
def time_diff(start_time, end_time)
  seconds_diff = (start_time - end_time).to_i.abs

  hours = seconds_diff / 3600
  seconds_diff -= hours * 3600

  minutes = seconds_diff / 60
  seconds_diff -= minutes * 60

  seconds = seconds_diff

  "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
end

# Run task export and capture json
task_data = {}
IO.popen(options["export_cmd"]) do |task_io|
  task_data = JSON.parse('[' + task_io.read + ']')
end

csv_data = CSV.generate({:force_quotes => true}) do |csv|
  # Header row
  csv << options["field_map"].keys + ["Email", "Start date", "Start time", "Duration"]

  task_data.each do |t| 
   
    # We can only export entries with time annotations 
    next if not t["annotations"]

    start_ts = nil

    t["annotations"].each do |ann|
      #eg {"entry"=>"20150103T174915Z", "description"=>"Started task"}   
      if ann["description"] == options["start_annotation"] then
        start_ts = DateTime.parse(ann["entry"])
        next
      end

      if ann["description"] == options["stop_annotation"] then
        # Ending with no beginning doesn't make sense
        next if not start_ts  

        end_ts = DateTime.parse(ann["entry"])
      
        row = [] # data row

        # Add in fields mapped by config
        options["field_map"].each do |key,val|
          if t[val].kind_of?(Array) then
            row << t[val].join(',')
          else
            row << t[val]
          end
        end 
        
        # Add common fields
        row += [
          options["toggl_email"],
          start_ts.to_date.to_s,
          start_ts.strftime("%H:%M:%S"),
          time_diff(start_ts.to_time,end_ts.to_time)
        ]
        
        # Add finished row to csv
        csv << row

        start_ts = nil
      end
    end
    
  end
end

# All done
puts csv_data
