---
name: moodle-tiny
description: Development guide for TinyMCE editor plugins (tiny_*). Use when extending the rich text editor with custom buttons, menus, dialogs, and content transformations.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# TinyMCE Editor Plugin Development

TinyMCE plugins extend the rich text editor with custom functionality - toolbar buttons, menus, dialogs, and content processing.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
lib/editor/tiny/plugins/yourplugin/
├── classes/
│   └── plugininfo.php        # Plugin registration (REQUIRED)
├── amd/src/
│   ├── plugin.js             # Main plugin module (REQUIRED)
│   ├── commands.js           # Editor commands
│   ├── ui.js                 # UI components
│   └── options.js            # Configuration options
├── version.php               # Plugin metadata (REQUIRED)
├── lang/en/
│   └── tiny_yourplugin.php   # Language strings
└── templates/                # Mustache templates for dialogs
```

## Plugin Info Class

```php
<?php
namespace tiny_yourplugin;

class plugininfo extends \editor_tiny\plugininfo {

    public static function is_enabled(
        \context $context,
        array $options,
        array $fpoptions,
        ?\editor_tiny\editor $editor = null
    ): bool {
        return true;
    }

    public static function get_plugin_configuration_for_context(
        \context $context,
        array $options,
        array $fpoptions,
        ?\editor_tiny\editor $editor = null
    ): array {
        return [
            'somesetting' => get_config('tiny_yourplugin', 'somesetting'),
        ];
    }
}
```

## Main Plugin Module (ES6)

```javascript
// amd/src/plugin.js
import {getTinyMCE} from 'editor_tiny/loader';
import {getPluginMetadata} from 'editor_tiny/utils';
import {component, pluginName} from './common';
import * as Commands from './commands';
import * as Options from './options';

export const getSetup = async() => {
    const [tinyMCE, metadata] = await Promise.all([
        getTinyMCE(),
        getPluginMetadata(component, pluginName),
    ]);

    return (editor) => {
        Options.register(editor);
        Commands.register(editor);

        // Add toolbar button
        editor.ui.registry.addButton(pluginName, {
            icon: metadata.icon,
            tooltip: metadata.name,
            onAction: () => Commands.execute(editor),
        });
    };
};
```

## Commands Module

```javascript
// amd/src/commands.js
import {pluginName} from './common';
import Modal from 'core/modal';
import Templates from 'core/templates';

export const register = (editor) => {
    editor.addCommand(`mce${pluginName}`, () => {
        execute(editor);
    });
};

export const execute = async(editor) => {
    const modal = await Modal.create({
        title: 'Your Plugin',
        body: Templates.render('tiny_yourplugin/dialog', {}),
        show: true,
    });

    modal.getRoot().on('click', '[data-action="insert"]', () => {
        const content = modal.getRoot().find('[name="content"]').val();
        editor.insertContent(content);
        modal.destroy();
    });
};
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| Media | `lib/editor/tiny/plugins/media/` | File picker |
| Link | `lib/editor/tiny/plugins/link/` | Dialogs |
| Equation | `lib/editor/tiny/plugins/equation/` | Math input |

## References

See [TinyMCE Patterns](references/patterns.md) for detailed examples.

## Resources

- TinyMCE API: https://www.tiny.cloud/docs/tinymce/6/
- Moodle Editor API: https://moodledev.io/docs/apis/core/editor
