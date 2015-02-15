# Taskwarrior CSV exporter for Toggl.com

Export taskwarrior start/stop times for import into toggl.com

## Usage

```
Usage: task-toggl.rb [options]

Options:
    -e, --email [EMAIL]              Toggl user email address
    -s, --start_annotation [TEXT]    Start annotation.  Default "Started task"
    -z, --stop_annotation [TEXT]     Stop annotation.  Default "Stopped task"
    -x, --export-cmd [CMD]           Command used to export task data.  Default "task export"
    -h, --help                       Prints this help
```

Options can be stored in a config file at ~/.task-toggl.yml, see included example.

## Notes

 - Only items that include start/stop time annotations are included in the script output.  
 - By default, the export is configured to map taskwarrior item descriptions to toggl's 'Project' field.  This is just how I like it, but if you want to use the taskwarrior project name and include the description as the toggl 'Task', then just update the field mapping in the config file.

Also see:
 - http://support.toggl.com/csv-import-new

