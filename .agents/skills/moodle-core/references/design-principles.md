# Moodle Design Principles & Component Library

This reference provides guidance for implementing UI features aligned with Moodle's design standards.

## Core Principles

**Central Purpose:** The Moodle Component Library documents frequently used UI components for consistent interface development.

**Key Philosophy:** Leverage existing documented components rather than creating custom solutions. This reduces redundancy and improves user experience.

**Design Foundation:** Bootstrap 5 components are included with Moodle 5.x+ (with Bootstrap 4 backwards compatibility through Moodle 6.0).

---

## Bootstrap 5 Migration (Moodle 5.x+)

### Class Name Changes

| Bootstrap 4 | Bootstrap 5 |
|-------------|-------------|
| `.badge-*` | `.text-bg-*` |
| `.ml-*` | `.ms-*` |
| `.mr-*` | `.me-*` |
| `.pl-*` | `.ps-*` |
| `.pr-*` | `.pe-*` |
| `.text-left` | `.text-start` |
| `.text-right` | `.text-end` |
| `.sr-only` | `.visually-hidden` |
| `.custom-select` | `.form-select` |
| `.custom-check` | `.form-check` |

### Data Attributes
Data attributes now use `bs` namespace:
- `data-toggle` → `data-bs-toggle`
- `data-target` → `data-bs-target`
- `data-dismiss` → `data-bs-dismiss`

### jQuery
jQuery is removed from Bootstrap 5, but Moodle provides a compatibility layer through 6.0.

Full migration guide: https://moodledev.io/docs/5.0/guides/bs5migration

---

## Component Library Reference

### Moodle UI Components

| Component | URL |
|-----------|-----|
| Activity Icons | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/activity-icons/ |
| Buttons | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/buttons/ |
| Course Cards | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/course-cards/ |
| Form Elements | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/form-elements/ |
| Icons | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/icons/ |
| Notifications | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/notifications/ |
| Toggle Input | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/toggle-input/ |
| Search Input | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/search-input/ |
| Collapsible Sections | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/collapsable-sections/ |
| Action Menus | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/action-menus/ |
| Dropdowns | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/dropdowns/ |
| HTML Modals | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/html-modals/ |
| Dynamic Tabs | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/components/dynamic-tabs/ |

### JavaScript Features

| Feature | URL |
|---------|-----|
| Confirm Dialog | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/javascript/confirm/ |
| Toast Notifications | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/javascript/toast/ |
| Sortable Lists | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/javascript/sortable-list/ |
| Moodle Charts | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/javascript/moodle-charts/ |

### Design Standards

| Standard | URL |
|----------|-----|
| Colours | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/themes/colours/ |
| Grids | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/themes/grids/ |
| Spacing | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/themes/spacing/ |
| Layout | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/themes/layout/ |
| Text | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/themes/text/ |

### Accessibility Guidelines

| Guideline | URL |
|-----------|-----|
| Links | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/accessibility/links/ |
| Colour Contrast | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/accessibility/colour-contrast/ |
| Keyboard Access | https://componentlibrary.moodle.com/admin/tool/componentlibrary/docspage.php/library/accessibility/keyboard-access/ |

---

## Design Guidelines Summary

### Components to Use

**Interactive Elements:** Buttons, toggles, dropdowns, modals, tabs, action menus
**Form Structures:** Standardized form inputs and elements
**Visual Indicators:** Badges, notifications, task indicators
**Navigation:** Action menus, collapsible sections
**Information Display:** Cards, footers, icons

### Design Standards to Follow

**Bootstrap Foundation:**
- All components built on Bootstrap
- Use Bootstrap utilities for layout, spacing, responsive design

**Accessibility:**
- Proper color contrast (4.5:1 minimum)
- Keyboard navigation for interactive elements
- Semantic HTML and ARIA labels
- Test for compliance

**Visual Consistency:**
- Follow Moodle's color palette
- Use consistent spacing and grids
- Maintain typographic hierarchy
- Consistent icon sizing

---

## Implementation Workflow

1. **Start here:** Review core principles
2. **Check for existing components:** Search Components section
3. **Review design standards:** Consult Themes section
4. **Verify accessibility:** Check Accessibility Guidelines
5. **Access detailed docs:** Visit component page URL
6. **Use Bootstrap:** Leverage Bootstrap as foundation

---

## Resources

- **Component Library:** https://componentlibrary.moodle.com/
- **Bootstrap 5 Docs:** https://getbootstrap.com/docs/5.0/
- **BS5 Migration Guide:** https://moodledev.io/docs/5.0/guides/bs5migration
- **Moodle Developer Docs:** https://docs.moodle.org/
