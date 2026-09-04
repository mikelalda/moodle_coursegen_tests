---
name: moodle-core
description: Core Moodle 5.x development practices including coding standards, security, JavaScript patterns, and CI validation. Use when developing any Moodle plugin to ensure code quality, security compliance, and adherence to Moodle conventions.
compatibility: Requires Moodle 5.x development environment. CI tools require moodle-plugin-ci in ../moodle-plugin-ci/
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Core Development Practices

This skill provides foundational guidance for Moodle 5.x plugin development, covering coding standards, security, JavaScript patterns, and quality validation.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` environment variable, or `../moodle` relative to plugin
- CI tools at `../moodle-plugin-ci/` (optional but recommended)

If `MOODLE_DIR` is not set, check parent directories for a Moodle installation (look for `config.php` and `lib/moodlelib.php`).

---

## Moodle Coding Style

Source: https://moodledev.io/general/development/policies/codingstyle

**Priority order**: Moodle coding style > PSR-12 > PSR-1

### PHP Basics
- Use long PHP tags (`<?php`), omit closing tag at end of file
- Maximum line length: 132 characters (180 max)
- Indent with 4 spaces, terminate lines with LF
- Filenames are lowercase only

### Naming Conventions
- **Classes/functions**: lowercase words separated by underscores
- **Variables**: lowercase words, no separator (`$courseid` not `$course_id`)
- **Constants**: UPPERCASE with underscores, prefixed with Frankenstyle (`PLUGINTYPE_PLUGINNAME_CONSTANT`)
- **Legacy functions**: prefix with Frankenstyle to avoid conflicts

### Strings
- Single quotes for literals or strings with many double quotes
- Double quotes when including variables or many single quotes

### Component Naming
- Format: `{plugintype}_{pluginname}` (e.g., `mod_forum`, `block_calendar`)
- Version format: `YYYYMMDDRR` (date + release increment)
- Maturity levels: `MATURITY_ALPHA`, `MATURITY_BETA`, `MATURITY_RC`, `MATURITY_STABLE`

---

## Security Essentials

**All user input is untrusted.** Follow these mandatory practices:

### Input Validation
```php
// REQUIRED: Always use parameter functions for user input
$id = required_param('id', PARAM_INT);
$name = optional_param('name', '', PARAM_ALPHANUMEXT);
```

### Capability Checking
```php
// REQUIRED: Check permissions before any action
require_capability('mod/forum:viewdiscussion', $context);

// Or for conditional display
if (has_capability('mod/forum:deletepost', $context)) {
    // Show delete button
}
```

### Output Escaping
```php
// REQUIRED: Escape all user-generated content
echo format_text($usertext, FORMAT_HTML, ['context' => $context]);
echo format_string($title);  // For single-line strings
echo s($rawtext);  // For plain text (HTML entities)
```

### Database Safety
```php
// REQUIRED: Use DML API, never raw SQL with user input
$DB->get_record('table', ['id' => $id]);
$DB->get_records_sql('SELECT * FROM {table} WHERE name = ?', [$name]);
```

---

## JavaScript Standards (Moodle 5.x+)

### Quick Rules
**DO:**
- Use vanilla JavaScript + Moodle helper libraries
- Write ES2015+ modules (transpiled via RequireJS)
- Use native Promises with `.then()/.catch()`
- Use `document.addEventListener()` for DOM interactions

**DON'T:**
- Use jQuery (deprecated since Moodle 5.x)
- Use YUI (removed from core)
- Use `.done()`, `.fail()`, `.always()` (jQuery promise methods)

### Module Structure
```
{component}/amd/src/{modulename}.js
```

Pattern: Create entry-point module with `init()` function:
```javascript
export const init = () => {
    document.addEventListener('click', handleClick);
};
```

### Key Libraries
| Library | Purpose |
|---------|---------|
| `core/str` | Language strings: `getString('key', 'component')` |
| `core/ajax` | Web service calls |
| `core/notification` | User notifications |
| `core/modal_factory` | Modal dialogs |

### Including JavaScript
```php
// In PHP
$PAGE->requires->js_call_amd('plugintype_pluginname/module', 'init', [$params]);
```

```mustache
{{! In templates }}
{{#js}}
require(['plugintype_pluginname/module'], function(Module) {
    Module.init();
});
{{/js}}
```

Full JavaScript guide: https://moodledev.io/docs/5.0/guides/javascript

---

## Database Patterns

### DML API (Required)
```php
// Single record
$record = $DB->get_record('table', ['id' => $id], '*', MUST_EXIST);

// Multiple records
$records = $DB->get_records('table', ['courseid' => $courseid]);

// Insert
$id = $DB->insert_record('table', $dataobject);

// Update
$DB->update_record('table', $dataobject);

// Delete
$DB->delete_records('table', ['id' => $id]);
```

### Transactions
```php
$transaction = $DB->start_delegated_transaction();
try {
    // Multiple operations
    $DB->insert_record(...);
    $DB->update_record(...);
    $transaction->allow_commit();
} catch (Exception $e) {
    $transaction->rollback($e);
}
```

---

## Internationalization

### Language Strings
All user-visible text must be externalized:

```php
// lang/en/plugintype_pluginname.php
$string['pluginname'] = 'My Plugin';
$string['setting_desc'] = 'Description with {$a} placeholder';

// Usage
get_string('pluginname', 'plugintype_pluginname');
get_string('setting_desc', 'plugintype_pluginname', $value);
```

### In Templates
```mustache
{{#str}}pluginname, plugintype_pluginname{{/str}}
{{#str}}setting_desc, plugintype_pluginname, {{value}}{{/str}}
```

---

## Accessibility (WCAG 2.1 AA)

- Proper heading hierarchy (h1 > h2 > h3)
- Alt text for images
- Keyboard navigation for all interactive elements
- Color contrast ratio minimum 4.5:1
- Form labels associated with inputs
- ARIA attributes where semantic HTML insufficient

---

## Quality Assurance

Before committing any code changes, run CI validation to ensure quality standards are met.

**Quick validation** (run the script):
```bash
./scripts/run-ci.sh
```

**Manual validation** (if script unavailable):
```bash
# Required checks
../moodle-plugin-ci/bin/moodle-plugin-ci phplint ./
../moodle-plugin-ci/bin/moodle-plugin-ci codechecker ./
../moodle-plugin-ci/bin/moodle-plugin-ci validate -m ${MOODLE_DIR} ./
```

For detailed CI validation procedures, customization options, and troubleshooting, see [CI validation guide](references/ci-validation.md).

---

## HTML Output

When generating HTML in PHP, prefer Mustache templates over `html_writer`. Templates provide better maintainability, accessibility, and design consistency.

**Preferred approach:**
```php
$data = ['items' => $items, 'title' => $title];
echo $OUTPUT->render_from_template('plugintype_pluginname/template', $data);
```

For situations where `html_writer` is necessary (simple links, tables), see [html_writer patterns](references/html-writer.md).

---

## UI Components

When implementing user interfaces, use Moodle's Component Library which provides Bootstrap 5-based components that are tested for accessibility and consistency.

**Bootstrap 5 key changes (Moodle 5.x+):**
- `.badge-*` → `.text-bg-*`
- `.ml-*` / `.mr-*` → `.ms-*` / `.me-*`
- `.text-left` → `.text-start`
- `.sr-only` → `.visually-hidden`
- `data-toggle` → `data-bs-toggle`

For component reference and design guidelines, see [design principles](references/design-principles.md).

Component Library: https://componentlibrary.moodle.com/

---

## Common Patterns

### Page Setup
```php
require_once('../../config.php');

$courseid = required_param('courseid', PARAM_INT);
$course = $DB->get_record('course', ['id' => $courseid], '*', MUST_EXIST);

require_login($course);
$context = context_course::instance($courseid);
require_capability('mod/plugin:view', $context);

$PAGE->set_url('/plugintype/pluginname/view.php', ['courseid' => $courseid]);
$PAGE->set_context($context);
$PAGE->set_title(get_string('pluginname', 'plugintype_pluginname'));
$PAGE->set_heading($course->fullname);

echo $OUTPUT->header();
// Page content
echo $OUTPUT->footer();
```

### Event Logging
```php
$event = \plugintype_pluginname\event\something_happened::create([
    'context' => $context,
    'objectid' => $id,
]);
$event->trigger();
```

### Scheduled Tasks
```php
// classes/task/my_task.php
namespace plugintype_pluginname\task;

class my_task extends \core\task\scheduled_task {
    public function get_name() {
        return get_string('mytask', 'plugintype_pluginname');
    }

    public function execute() {
        // Task logic
    }
}
```

---

## References

- [CI Validation Guide](references/ci-validation.md) - Detailed quality checks and troubleshooting
- [HTML Writer Patterns](references/html-writer.md) - When and how to use html_writer
- [Design Principles](references/design-principles.md) - UI components and Bootstrap 5 migration

## External Resources

- Moodle Coding Style: https://moodledev.io/general/development/policies/codingstyle
- JavaScript Guide: https://moodledev.io/docs/5.0/guides/javascript
- Component Library: https://componentlibrary.moodle.com/
- Bootstrap 5 Migration: https://moodledev.io/docs/5.0/guides/bs5migration
