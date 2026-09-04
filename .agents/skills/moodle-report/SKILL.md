---
name: moodle-report
description: Development guide for Moodle report plugins (report_*). Use when creating reports that display data, statistics, logs, or analytics for courses, users, or the site.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Report Plugin Development

Report plugins display data, statistics, and analytics. They can be site-wide, course-level, or user-specific.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
report/yourreport/
├── index.php                 # Main report page (REQUIRED)
├── lib.php                   # Navigation hooks
├── version.php               # Plugin metadata (REQUIRED)
├── settings.php              # Admin settings
├── classes/
│   ├── output/               # Renderables
│   └── table/                # Table classes
├── lang/en/
│   └── report_yourreport.php # Language strings
├── db/access.php             # Capabilities
└── templates/                # Mustache templates
```

## Main Report Page

```php
<?php
require_once('../../config.php');

$courseid = required_param('id', PARAM_INT);
$course = $DB->get_record('course', ['id' => $courseid], '*', MUST_EXIST);

require_login($course);
$context = context_course::instance($courseid);
require_capability('report/yourreport:view', $context);

$PAGE->set_url('/report/yourreport/index.php', ['id' => $courseid]);
$PAGE->set_context($context);
$PAGE->set_title(get_string('pluginname', 'report_yourreport'));
$PAGE->set_heading($course->fullname);
$PAGE->set_pagelayout('report');

echo $OUTPUT->header();
echo $OUTPUT->heading(get_string('pluginname', 'report_yourreport'));

// Display report content
$table = new \report_yourreport\table\report_table('yourreport', $courseid);
$table->out(25, true);

echo $OUTPUT->footer();
```

## Navigation Hook

```php
<?php
// lib.php
function report_yourreport_extend_navigation_course($navigation, $course, $context) {
    if (has_capability('report/yourreport:view', $context)) {
        $url = new moodle_url('/report/yourreport/index.php', ['id' => $course->id]);
        $navigation->add(
            get_string('pluginname', 'report_yourreport'),
            $url,
            navigation_node::TYPE_SETTING,
            null,
            'yourreport',
            new pix_icon('i/report', '')
        );
    }
}
```

## Table Class

```php
<?php
namespace report_yourreport\table;

class report_table extends \table_sql {

    public function __construct($uniqueid, $courseid) {
        parent::__construct($uniqueid);

        $this->define_columns(['fullname', 'email', 'lastaccess']);
        $this->define_headers(['Name', 'Email', 'Last Access']);

        $this->set_sql(
            'u.id, u.firstname, u.lastname, u.email, ul.timeaccess',
            '{user} u JOIN {user_lastaccess} ul ON u.id = ul.userid',
            'ul.courseid = :courseid',
            ['courseid' => $courseid]
        );

        $this->define_baseurl(new \moodle_url('/report/yourreport/index.php', ['id' => $courseid]));
    }

    public function col_fullname($row) {
        return fullname($row);
    }

    public function col_lastaccess($row) {
        return userdate($row->timeaccess);
    }
}
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| Log | `report/log/` | Event logs |
| Outline | `report/outline/` | Activity summary |
| Participation | `report/participation/` | User activity |

## References

See [Report Patterns](references/patterns.md) for detailed examples.
