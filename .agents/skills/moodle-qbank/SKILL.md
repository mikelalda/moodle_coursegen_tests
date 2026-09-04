---
name: moodle-qbank
description: Development guide for Moodle question bank plugins (qbank_*). Use when extending the question bank with custom columns, bulk actions, or question management features.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Question Bank Plugin Development

Question bank plugins extend the question bank interface with custom columns, actions, and views.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
question/bank/yourplugin/
├── classes/
│   ├── column.php            # Custom column class
│   ├── plugin_feature.php    # Feature registration
│   └── bulk_action.php       # Bulk action class
├── version.php               # Plugin metadata (REQUIRED)
├── lang/en/
│   └── qbank_yourplugin.php  # Language strings
└── db/access.php             # Capabilities
```

## Custom Column

```php
<?php
namespace qbank_yourplugin;

class column extends \core_question\local\bank\column_base {

    public function get_name(): string {
        return 'yourcolumn';
    }

    public function get_title(): string {
        return get_string('yourcolumn', 'qbank_yourplugin');
    }

    protected function display_content($question, $rowclasses): void {
        echo html_writer::span($question->yourfield, 'qbank-yourcolumn');
    }
}
```

## Plugin Feature Registration

```php
<?php
namespace qbank_yourplugin;

class plugin_feature extends \core_question\local\bank\plugin_features_base {

    public function get_question_columns($qbank): array {
        return [new column($qbank)];
    }

    public function get_bulk_actions(): array {
        return [new bulk_action()];
    }
}
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| View Creator | `question/bank/viewcreator/` | Column |
| History | `question/bank/history/` | Actions |
| Statistics | `question/bank/statistics/` | Data display |

## References

See [Question Bank Patterns](references/patterns.md) for detailed examples.
