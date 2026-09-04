---
name: moodle-block
description: Development guide for Moodle block plugins. Use when creating, modifying, or debugging block plugins that display content in sidebars and page regions. Covers block class implementation, capabilities, and configuration.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Block Plugin Development

Block plugins add content regions to Moodle pages, typically appearing in sidebars. They can display information, provide navigation, or offer quick access to features.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices (coding standards, security, CI validation), also activate the `moodle-core` skill.

## File Structure

```
block_[blockname]/
├── block_[blockname].php       # Main block class (REQUIRED)
├── version.php                 # Version and dependencies (REQUIRED)
├── lang/
│   └── en/
│       └── block_[blockname].php  # Language strings (REQUIRED)
├── db/
│   ├── access.php              # Capabilities
│   ├── install.xml             # Database schema
│   └── upgrade.php             # Database upgrades
├── classes/                    # Autoloaded classes (PSR-4)
├── styles.css                  # Block-specific styles
├── settings.php                # Admin settings
├── edit_form.php               # Instance configuration form
└── templates/                  # Mustache templates
```

## Main Block Class

The main class must extend `block_base` or `block_list`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

class block_[blockname] extends block_base {

    public function init() {
        $this->title = get_string('pluginname', 'block_[blockname]');
    }

    public function get_content() {
        if ($this->content !== null) {
            return $this->content;
        }

        $this->content = new stdClass();
        $this->content->text = '';
        $this->content->footer = '';

        // Build content here
        $this->content->text = $this->render_block_content();

        return $this->content;
    }

    public function applicable_formats() {
        return [
            'all' => false,
            'site' => true,
            'site-index' => true,
            'course-view' => true,
            'my' => true,
        ];
    }

    public function instance_allow_multiple() {
        return false;
    }

    public function has_config() {
        return true;
    }

    private function render_block_content() {
        global $OUTPUT;

        $data = $this->get_template_data();
        return $OUTPUT->render_from_template('block_[blockname]/content', $data);
    }
}
```

## Version File

```php
<?php
defined('MOODLE_INTERNAL') || die();

$plugin->component = 'block_[blockname]';
$plugin->version = 2024010100;  // YYYYMMDDXX format
$plugin->requires = 2023100900; // Moodle 5.0
$plugin->maturity = MATURITY_STABLE;
$plugin->release = 'v1.0';
```

## Language Strings

Minimum required strings in `lang/en/block_[blockname].php`:

```php
<?php
$string['pluginname'] = 'Your Block Name';
$string['[blockname]:addinstance'] = 'Add a new Your Block Name block';
$string['[blockname]:myaddinstance'] = 'Add Your Block Name to Dashboard';
```

## Capabilities

Define in `db/access.php`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

$capabilities = [
    'block/[blockname]:addinstance' => [
        'captype' => 'write',
        'contextlevel' => CONTEXT_BLOCK,
        'archetypes' => [
            'editingteacher' => CAP_ALLOW,
            'manager' => CAP_ALLOW,
        ],
    ],
    'block/[blockname]:myaddinstance' => [
        'captype' => 'write',
        'contextlevel' => CONTEXT_SYSTEM,
        'archetypes' => [
            'user' => CAP_ALLOW,
        ],
    ],
];
```

## Instance Configuration

Create `edit_form.php` for per-instance settings:

```php
<?php
class block_[blockname]_edit_form extends block_edit_form {

    protected function specific_definition($mform) {
        $mform->addElement('header', 'config_header',
            get_string('blocksettings', 'block'));

        $mform->addElement('text', 'config_title',
            get_string('configtitle', 'block_[blockname]'));
        $mform->setDefault('config_title', '');
        $mform->setType('config_title', PARAM_TEXT);

        $options = [
            5 => '5',
            10 => '10',
            15 => '15',
        ];
        $mform->addElement('select', 'config_numitems',
            get_string('confignumitems', 'block_[blockname]'), $options);
        $mform->setDefault('config_numitems', 10);
    }
}
```

Access config in block class:

```php
public function get_content() {
    // Access instance config
    $numitems = $this->config->numitems ?? 10;
    $title = $this->config->title ?? '';

    if (!empty($title)) {
        $this->title = $title;
    }
}
```

## Required Library Includes

Some Moodle APIs require manual includes:

```php
// Grade-related functionality
require_once($CFG->libdir . '/gradelib.php');
require_once($CFG->dirroot . '/grade/lib.php');

// Course-related functionality
require_once($CFG->dirroot . '/course/lib.php');

// User-related functionality
require_once($CFG->dirroot . '/user/lib.php');

// Group-related functionality
require_once($CFG->libdir . '/grouplib.php');
```

## Context and Permissions

```php
public function get_content() {
    global $USER, $COURSE;

    // Get block context
    $context = context_block::instance($this->instance->id);

    // Check capabilities
    if (!has_capability('block/[blockname]:view', $context)) {
        return null;
    }

    // Get course context if needed
    $coursecontext = context_course::instance($COURSE->id);
}
```

## Common Block Types

### List Block

For blocks that display lists:

```php
class block_[blockname] extends block_list {

    public function init() {
        $this->title = get_string('pluginname', 'block_[blockname]');
    }

    public function get_content() {
        if ($this->content !== null) {
            return $this->content;
        }

        $this->content = new stdClass();
        $this->content->items = [];
        $this->content->icons = [];
        $this->content->footer = '';

        // Add list items
        $this->content->items[] = html_writer::link(
            new moodle_url('/path/to/page.php'),
            get_string('linktext', 'block_[blockname]')
        );
        $this->content->icons[] = $OUTPUT->pix_icon('i/item', '');

        return $this->content;
    }
}
```

### AJAX-Enabled Block

For dynamic content:

```php
public function get_content() {
    global $PAGE;

    // Include AMD module
    $PAGE->requires->js_call_amd('block_[blockname]/main', 'init', [
        'blockid' => $this->instance->id,
    ]);

    $this->content = new stdClass();
    $this->content->text = '<div id="block-[blockname]-content" data-blockid="' .
                           $this->instance->id . '"></div>';

    return $this->content;
}
```

## Reference Implementations

Study these core blocks for patterns:

| Block | Path | Pattern |
|-------|------|---------|
| HTML | `blocks/html/` | Simple content block |
| Navigation | `blocks/navigation/` | Complex navigation |
| Recent Activity | `blocks/recent_activity/` | Database queries |
| My Overview | `blocks/myoverview/` | User context |

## Testing Checklist

- [ ] PHP syntax valid (`phplint`)
- [ ] Required files exist with correct naming
- [ ] Block class extends `block_base` or `block_list`
- [ ] `init()` and `get_content()` implemented
- [ ] Language strings include pluginname and capability strings
- [ ] Capabilities defined correctly
- [ ] Block appears in correct page locations
- [ ] Configuration saves and loads properly

## Debugging

Enable debugging in Moodle:

```php
// In config.php
$CFG->debug = DEBUG_DEVELOPER;
$CFG->debugdisplay = 1;
```

Debug output in block:

```php
if (debugging()) {
    debugging('Block data: ' . print_r($data, true), DEBUG_DEVELOPER);
}
```

## Resources

- Block API: https://moodledev.io/docs/apis/core/block
- Plugin Development: https://moodledev.io/docs/apis/plugintypes
