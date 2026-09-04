---
name: moodle-filter
description: Development guide for Moodle filter plugins (filter_*). Use when creating text filters that transform content, embed media, convert notation, or add interactive elements.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Filter Plugin Development

Filter plugins transform text content - embedding media, converting notation (LaTeX), adding tooltips, or enhancing text.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
filter/yourplugin/
├── filter.php                # Main filter class (REQUIRED)
├── version.php               # Plugin metadata (REQUIRED)
├── settings.php              # Admin settings
├── lang/en/
│   └── filter_yourplugin.php # Language strings
├── db/access.php             # Capabilities
├── amd/src/                  # JavaScript modules
└── styles.css                # Filter styles
```

## Main Filter Class

```php
<?php
defined('MOODLE_INTERNAL') || die();

class filter_yourplugin extends moodle_text_filter {

    public function filter($text, array $options = []) {
        // Quick bail-out if no markers
        if (strpos($text, '[[') === false) {
            return $text;
        }

        $pattern = '/\[\[([^\]]+)\]\]/';
        return preg_replace_callback($pattern, function($matches) {
            return $this->process_match($matches[1]);
        }, $text);
    }

    private function process_match($content) {
        return html_writer::span($content, 'filter-highlight');
    }

    public function setup($page, $context) {
        $page->requires->css('/filter/yourplugin/styles.css');
    }
}
```

## Performance Tips

```php
public function filter($text, array $options = []) {
    // 1. Quick check before regex
    if (empty($text) || strpos($text, $this->marker) === false) {
        return $text;
    }

    // 2. Static cache for repeated calls
    static $cache = [];
    $hash = md5($text);
    if (isset($cache[$hash])) {
        return $cache[$hash];
    }

    $result = $this->do_filter($text);
    $cache[$hash] = $result;
    return $result;
}
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| MathJax | `filter/mathjaxloader/` | Math notation |
| Multimedia | `filter/mediaplugin/` | Media embedding |
| Glossary | `filter/glossary/` | Auto-linking |

## References

See [Filter Patterns](references/patterns.md) for detailed examples.
