---
name: moodle-local
description: Development guide for Moodle local plugins (local_*). Use when creating custom functionality that doesn't fit standard plugin types - admin tools, integrations, course enhancements, or system extensions.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Local Plugin Development

Local plugins provide custom functionality that doesn't fit standard plugin types - admin tools, integrations, scheduled tasks, or extending core features.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
local/yourplugin/
├── lib.php                   # Hook implementations
├── index.php                 # Main page (optional)
├── version.php               # Plugin metadata (REQUIRED)
├── settings.php              # Admin settings
├── classes/
│   ├── form/                 # Form classes
│   ├── external/             # Web service APIs
│   ├── event/                # Event classes
│   ├── privacy/              # GDPR provider
│   └── task/                 # Scheduled tasks
├── db/
│   ├── install.xml           # Database schema
│   ├── upgrade.php           # Upgrades
│   ├── access.php            # Capabilities
│   ├── services.php          # Web services
│   └── tasks.php             # Task definitions
├── lang/en/
│   └── local_yourplugin.php  # Language strings
└── templates/                # Mustache templates
```

## Navigation Hooks

```php
<?php
// lib.php

// Add to course admin menu
function local_yourplugin_extend_settings_navigation($settingsnav, $context) {
    global $PAGE;

    if ($context->contextlevel == CONTEXT_COURSE &&
        has_capability('local/yourplugin:manage', $context)) {

        if ($node = $settingsnav->find('courseadmin', navigation_node::TYPE_COURSE)) {
            $url = new moodle_url('/local/yourplugin/index.php',
                ['courseid' => $PAGE->course->id]);
            $node->add(
                get_string('pluginname', 'local_yourplugin'),
                $url,
                navigation_node::NODETYPE_LEAF,
                'local_yourplugin',
                'local_yourplugin',
                new pix_icon('i/settings', '')
            );
        }
    }
}

// Add to site admin
function local_yourplugin_extend_navigation($navigation) {
    if (has_capability('local/yourplugin:viewadmin', context_system::instance())) {
        $node = $navigation->add(
            get_string('pluginname', 'local_yourplugin'),
            new moodle_url('/local/yourplugin/admin.php')
        );
    }
}
```

## Scheduled Task

```php
<?php
// classes/task/sync_task.php
namespace local_yourplugin\task;

class sync_task extends \core\task\scheduled_task {

    public function get_name() {
        return get_string('synctask', 'local_yourplugin');
    }

    public function execute() {
        mtrace('Starting sync...');
        // Task logic here
        mtrace('Sync complete.');
    }
}

// db/tasks.php
$tasks = [
    [
        'classname' => 'local_yourplugin\task\sync_task',
        'blocking' => 0,
        'minute' => '0',
        'hour' => '*/6',
        'day' => '*',
        'month' => '*',
        'dayofweek' => '*',
    ],
];
```

## Web Service API

```php
<?php
// classes/external/get_data.php
namespace local_yourplugin\external;

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_value;

class get_data extends external_api {

    public static function execute_parameters() {
        return new external_function_parameters([
            'id' => new external_value(PARAM_INT, 'Record ID'),
        ]);
    }

    public static function execute($id) {
        global $DB;
        $params = self::validate_parameters(self::execute_parameters(), ['id' => $id]);
        return $DB->get_record('local_yourplugin', ['id' => $params['id']], '*', MUST_EXIST);
    }

    public static function execute_returns() {
        return new external_single_structure([
            'id' => new external_value(PARAM_INT),
            'name' => new external_value(PARAM_TEXT),
        ]);
    }
}
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| MoodleNet | `local/moodlenet/` | Integration |
| Course Completion | Various | Automation |

## References

See [Local Plugin Patterns](references/patterns.md) for detailed examples.
