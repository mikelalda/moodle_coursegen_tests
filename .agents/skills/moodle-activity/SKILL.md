---
name: moodle-activity
description: Development guide for Moodle activity module plugins (mod_*). Use when creating activities that integrate with courses, gradebook, and completion tracking. Covers lib.php hooks, mod_form, view scripts, and grading integration.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Activity Module Development

Activity modules extend Moodle's course structure by adding new learning activities. They integrate with the gradebook, completion tracking, and provide rich interactions for students and teachers.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices (coding standards, security, CI validation), also activate the `moodle-core` skill.

## File Structure

```
mod/yourmodule/
├── lib.php                    # Core Moodle hooks (REQUIRED)
├── locallib.php               # Module-specific classes
├── mod_form.php               # Activity configuration form (REQUIRED)
├── view.php                   # Main activity display (REQUIRED)
├── index.php                  # Course activity listing
├── version.php                # Plugin metadata (REQUIRED)
├── settings.php               # Admin settings
├── backup/                    # Backup and restore
├── classes/
│   ├── external/              # Web service APIs
│   ├── event/                 # Event classes
│   ├── privacy/               # GDPR provider
│   └── task/                  # Scheduled tasks
├── db/
│   ├── install.xml            # Database schema
│   ├── upgrade.php            # Database upgrades
│   ├── access.php             # Capabilities
│   ├── services.php           # Web services
│   └── tasks.php              # Task definitions
├── lang/en/
│   └── mod_yourmodule.php     # Language strings
├── templates/                 # Mustache templates
└── tests/                     # Unit tests
```

## Core Library (lib.php)

Essential functions that Moodle calls:

```php
<?php
defined('MOODLE_INTERNAL') || die();

/**
 * Declare supported features
 */
function yourmodule_supports($feature) {
    return match ($feature) {
        FEATURE_MOD_ARCHETYPE => MOD_ARCHETYPE_ASSIGNMENT,
        FEATURE_GROUPS => true,
        FEATURE_GROUPINGS => true,
        FEATURE_MOD_INTRO => true,
        FEATURE_COMPLETION_TRACKS_VIEWS => true,
        FEATURE_COMPLETION_HAS_RULES => true,
        FEATURE_GRADE_HAS_GRADE => true,
        FEATURE_BACKUP_MOODLE2 => true,
        FEATURE_SHOW_DESCRIPTION => true,
        FEATURE_MOD_PURPOSE => MOD_PURPOSE_ASSESSMENT,
        default => null,
    };
}

/**
 * Add instance - called when activity is created
 */
function yourmodule_add_instance(stdClass $data, ?mod_yourmodule_mod_form $form = null) {
    global $DB;

    $data->timecreated = time();
    $data->timemodified = $data->timecreated;

    // Handle intro field
    if (!isset($data->intro)) {
        $data->intro = '';
    }
    if (!isset($data->introformat)) {
        $data->introformat = FORMAT_HTML;
    }

    $data->id = $DB->insert_record('yourmodule', $data);

    // Create grade item
    if (!empty($data->grade)) {
        yourmodule_grade_item_update($data);
    }

    return $data->id;
}

/**
 * Update instance
 */
function yourmodule_update_instance(stdClass $data, ?mod_yourmodule_mod_form $form = null) {
    global $DB;

    $data->timemodified = time();
    $data->id = $data->instance;

    $result = $DB->update_record('yourmodule', $data);
    yourmodule_grade_item_update($data);

    return $result;
}

/**
 * Delete instance
 */
function yourmodule_delete_instance($id) {
    global $DB;

    if (!$yourmodule = $DB->get_record('yourmodule', ['id' => $id])) {
        return false;
    }

    // Delete related data first
    $DB->delete_records('yourmodule_submissions', ['yourmodule' => $id]);

    // Delete grade item
    yourmodule_grade_item_delete($yourmodule);

    // Delete files
    $cm = get_coursemodule_from_instance('yourmodule', $id);
    if ($cm) {
        $context = context_module::instance($cm->id);
        $fs = get_file_storage();
        $fs->delete_area_files($context->id, 'mod_yourmodule');
    }

    // Delete main record
    $DB->delete_records('yourmodule', ['id' => $id]);

    return true;
}
```

## Grading Integration

```php
function yourmodule_grade_item_update($yourmodule, $grades = null) {
    global $CFG;
    require_once($CFG->libdir . '/gradelib.php');

    $item = [
        'itemname' => clean_param($yourmodule->name, PARAM_NOTAGS),
    ];

    if ($yourmodule->grade > 0) {
        $item['gradetype'] = GRADE_TYPE_VALUE;
        $item['grademax'] = $yourmodule->grade;
        $item['grademin'] = 0;
    } else if ($yourmodule->grade < 0) {
        $item['gradetype'] = GRADE_TYPE_SCALE;
        $item['scaleid'] = -$yourmodule->grade;
    } else {
        $item['gradetype'] = GRADE_TYPE_NONE;
    }

    return grade_update('mod/yourmodule', $yourmodule->course, 'mod',
                       'yourmodule', $yourmodule->id, 0, $grades, $item);
}

function yourmodule_grade_item_delete($yourmodule) {
    global $CFG;
    require_once($CFG->libdir . '/gradelib.php');

    return grade_update('mod/yourmodule', $yourmodule->course, 'mod',
                       'yourmodule', $yourmodule->id, 0, null, ['deleted' => 1]);
}
```

## Configuration Form (mod_form.php)

```php
<?php
defined('MOODLE_INTERNAL') || die();

require_once($CFG->dirroot . '/course/moodleform_mod.php');

class mod_yourmodule_mod_form extends moodleform_mod {

    public function definition() {
        $mform = $this->_form;

        // General section
        $mform->addElement('header', 'general', get_string('general', 'form'));

        $mform->addElement('text', 'name', get_string('name'), ['size' => 64]);
        $mform->setType('name', PARAM_TEXT);
        $mform->addRule('name', null, 'required', null, 'client');

        $this->standard_intro_elements();

        // Activity-specific settings
        $mform->addElement('header', 'contentsection',
            get_string('content', 'mod_yourmodule'));

        // ... add your fields

        // Standard elements
        $this->standard_grading_coursemodule_elements();
        $this->standard_coursemodule_elements();
        $this->add_action_buttons();
    }

    public function validation($data, $files) {
        $errors = parent::validation($data, $files);
        // Add custom validation
        return $errors;
    }
}
```

## View Script (view.php)

```php
<?php
require_once('../../config.php');
require_once($CFG->dirroot . '/mod/yourmodule/lib.php');

$id = optional_param('id', 0, PARAM_INT); // Course Module ID

list($course, $cm) = get_course_and_cm_from_cmid($id, 'yourmodule');
$yourmodule = $DB->get_record('yourmodule', ['id' => $cm->instance], '*', MUST_EXIST);

require_login($course, true, $cm);
$context = context_module::instance($cm->id);
require_capability('mod/yourmodule:view', $context);

// Log view event
$event = \mod_yourmodule\event\course_module_viewed::create([
    'objectid' => $yourmodule->id,
    'context' => $context,
]);
$event->trigger();

// Mark as viewed for completion
$completion = new completion_info($course);
$completion->set_module_viewed($cm);

// Page setup
$PAGE->set_url('/mod/yourmodule/view.php', ['id' => $cm->id]);
$PAGE->set_title(format_string($yourmodule->name));
$PAGE->set_heading(format_string($course->fullname));
$PAGE->set_context($context);

echo $OUTPUT->header();
echo $OUTPUT->heading(format_string($yourmodule->name));

// Show intro
if (trim(strip_tags($yourmodule->intro))) {
    echo $OUTPUT->box_start('mod_introbox');
    echo format_module_intro('yourmodule', $yourmodule, $cm->id);
    echo $OUTPUT->box_end();
}

// Render content based on capability
if (has_capability('mod/yourmodule:submit', $context)) {
    // Student view
} else if (has_capability('mod/yourmodule:grade', $context)) {
    // Teacher view
}

echo $OUTPUT->footer();
```

## Capabilities (db/access.php)

```php
<?php
defined('MOODLE_INTERNAL') || die();

$capabilities = [
    'mod/yourmodule:addinstance' => [
        'riskbitmask' => RISK_XSS,
        'captype' => 'write',
        'contextlevel' => CONTEXT_COURSE,
        'archetypes' => [
            'editingteacher' => CAP_ALLOW,
            'manager' => CAP_ALLOW,
        ],
    ],
    'mod/yourmodule:view' => [
        'captype' => 'read',
        'contextlevel' => CONTEXT_MODULE,
        'archetypes' => [
            'guest' => CAP_ALLOW,
            'student' => CAP_ALLOW,
            'teacher' => CAP_ALLOW,
            'editingteacher' => CAP_ALLOW,
            'manager' => CAP_ALLOW,
        ],
    ],
    'mod/yourmodule:submit' => [
        'riskbitmask' => RISK_SPAM,
        'captype' => 'write',
        'contextlevel' => CONTEXT_MODULE,
        'archetypes' => [
            'student' => CAP_ALLOW,
        ],
    ],
    'mod/yourmodule:grade' => [
        'riskbitmask' => RISK_XSS,
        'captype' => 'write',
        'contextlevel' => CONTEXT_MODULE,
        'archetypes' => [
            'teacher' => CAP_ALLOW,
            'editingteacher' => CAP_ALLOW,
            'manager' => CAP_ALLOW,
        ],
    ],
];
```

## Database Schema (db/install.xml)

**Critical**: Follow XMLDB strict formatting:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<XMLDB PATH="mod/yourmodule/db" VERSION="2024010100"
    COMMENT="XMLDB file for mod/yourmodule"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="../../../lib/xmldb/xmldb.xsd">
  <TABLES>
    <TABLE NAME="yourmodule" COMMENT="Main activity table">
      <FIELDS>
        <FIELD NAME="id" TYPE="int" LENGTH="10" NOTNULL="true" SEQUENCE="true"/>
        <FIELD NAME="course" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
        <FIELD NAME="name" TYPE="char" LENGTH="1333" NOTNULL="true" SEQUENCE="false"/>
        <FIELD NAME="intro" TYPE="text" NOTNULL="false" SEQUENCE="false"/>
        <FIELD NAME="introformat" TYPE="int" LENGTH="4" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
        <FIELD NAME="grade" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
        <FIELD NAME="timecreated" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
        <FIELD NAME="timemodified" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
      </FIELDS>
      <KEYS>
        <KEY NAME="primary" TYPE="primary" FIELDS="id"/>
        <KEY NAME="course" TYPE="foreign" FIELDS="course" REFTABLE="course" REFFIELDS="id"/>
      </KEYS>
    </TABLE>
  </TABLES>
</XMLDB>
```

**XMLDB Requirements**:
- Root element must have `COMMENT` attribute
- All non-primary fields must have `SEQUENCE="false"`
- Include XML namespace declarations

## Common Issues

### 1. Null Constraint Violation
Always set defaults for intro fields:
```php
if (!isset($data->intro)) $data->intro = '';
if (!isset($data->introformat)) $data->introformat = FORMAT_HTML;
```

### 2. POST Form Detection
Use proper form detection:
```php
// WRONG: optional_param doesn't work for submit buttons
$submit = optional_param('submit', '', PARAM_TEXT);

// CORRECT: Check POST directly
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['submit'])) {
    require_sesskey();
}
```

### 3. Completion Tracking
Use full course object:
```php
// WRONG: completion_info needs course object, not ID
$completion = new completion_info($cm->course);

// CORRECT
$course = get_course($cm->course);
$completion = new completion_info($course);
```

## Reference Implementations

Study these core modules:

| Module | Path | Pattern |
|--------|------|---------|
| Assignment | `mod/assign/` | Full-featured activity |
| Page | `mod/page/` | Simple resource |
| Quiz | `mod/quiz/` | Complex grading |
| Forum | `mod/forum/` | User interaction |

## References

For detailed patterns, code examples, and anti-patterns:
- See [Activity Patterns](references/patterns.md)

## Resources

- Activity Module API: https://moodledev.io/docs/apis/plugintypes/mod
- Grading API: https://moodledev.io/docs/apis/core/grading
