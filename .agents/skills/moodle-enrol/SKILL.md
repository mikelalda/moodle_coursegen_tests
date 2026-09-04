---
name: moodle-enrol
description: Development guide for Moodle enrolment plugins (enrol_*). Use when creating custom enrolment methods that control how users are enrolled in courses.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Enrolment Plugin Development

Enrolment plugins control how users are enrolled in courses - self-enrolment, payment, external sync, etc.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
enrol/yourplugin/
├── lib.php                   # Main plugin class (REQUIRED)
├── version.php               # Plugin metadata (REQUIRED)
├── settings.php              # Admin settings
├── edit.php                  # Instance edit page
├── edit_form.php             # Instance form
├── lang/en/
│   └── enrol_yourplugin.php  # Language strings
├── db/
│   ├── access.php            # Capabilities
│   └── tasks.php             # Scheduled tasks
└── classes/task/             # Task classes
```

## Main Plugin Class

```php
<?php
class enrol_yourplugin_plugin extends enrol_plugin {

    public function allow_unenrol(stdClass $instance) {
        return true;
    }

    public function allow_manage(stdClass $instance) {
        return true;
    }

    public function show_enrolme_link(stdClass $instance) {
        return ($instance->status == ENROL_INSTANCE_ENABLED);
    }

    public function can_self_enrol(stdClass $instance, $checkuserenrolment = true) {
        global $USER;
        if ($checkuserenrolment && $this->get_user_enrolment($instance, $USER->id)) {
            return get_string('alreadyenrolled', 'enrol_yourplugin');
        }
        return true;
    }

    public function enrol_page_hook(stdClass $instance) {
        // Return enrolment form/button
    }

    public function get_newinstance_link($courseid) {
        $context = context_course::instance($courseid);
        if (!has_capability('moodle/course:enrolconfig', $context)) {
            return null;
        }
        return new moodle_url('/enrol/yourplugin/edit.php', ['courseid' => $courseid]);
    }
}
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| Self | `enrol/self/` | Self-enrol with key |
| Manual | `enrol/manual/` | Manual enrolment |
| PayPal | `enrol/paypal/` | Payment |

## References

See [Enrolment Patterns](references/patterns.md) for detailed examples.
