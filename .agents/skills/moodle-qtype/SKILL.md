---
name: moodle-qtype
description: Development guide for Moodle question type plugins (qtype_*). Use when creating custom question types for quizzes with answer processing, grading logic, and response rendering.
compatibility: Requires Moodle 5.x development environment
metadata:
  author: momopda
  version: "1.0.0"
---

# Moodle Question Type Development

Question type plugins define how questions are displayed, answered, and graded in Moodle quizzes.

## Environment Setup

This skill expects:
- Plugin code in the current working directory
- Moodle source at `$MOODLE_DIR` or `../moodle` relative to plugin

## Recommended Skills

For base Moodle development practices, also activate the `moodle-core` skill.

## File Structure

```
question/type/yourqtype/
├── questiontype.php          # Question type class (REQUIRED)
├── question.php              # Question class (REQUIRED)
├── renderer.php              # Rendering class (REQUIRED)
├── edit_yourqtype_form.php   # Editing form (REQUIRED)
├── version.php               # Plugin metadata (REQUIRED)
├── lang/en/
│   └── qtype_yourqtype.php   # Language strings
├── db/
│   ├── install.xml           # Database schema
│   └── upgrade.php           # Upgrades
└── tests/                    # PHPUnit tests
```

## Question Type Class

```php
<?php
class qtype_yourqtype extends question_type {

    public function get_question_options($question) {
        global $DB;
        $question->options = $DB->get_record('qtype_yourqtype_options',
            ['questionid' => $question->id], '*', MUST_EXIST);
        return true;
    }

    public function save_question_options($question) {
        global $DB;
        $options = new stdClass();
        $options->questionid = $question->id;
        // Save question-specific options
        $DB->insert_record('qtype_yourqtype_options', $options);
    }

    public function delete_question($questionid, $contextid) {
        global $DB;
        $DB->delete_records('qtype_yourqtype_options', ['questionid' => $questionid]);
        parent::delete_question($questionid, $contextid);
    }
}
```

## Question Class

```php
<?php
class qtype_yourqtype_question extends question_graded_automatically {

    public function get_expected_data() {
        return ['answer' => PARAM_RAW_TRIMMED];
    }

    public function is_complete_response(array $response) {
        return !empty($response['answer']);
    }

    public function grade_response(array $response) {
        $fraction = $this->calculate_grade($response['answer']);
        return [$fraction, question_state::graded_state_for_fraction($fraction)];
    }

    public function get_correct_response() {
        return ['answer' => $this->correctanswer];
    }
}
```

## Renderer Class

```php
<?php
class qtype_yourqtype_renderer extends qtype_renderer {

    public function formulation_and_controls(question_attempt $qa,
            question_display_options $options) {
        $question = $qa->get_question();
        $response = $qa->get_last_qt_data();

        $inputname = $qa->get_qt_field_name('answer');
        $inputattributes = [
            'type' => 'text',
            'name' => $inputname,
            'value' => $response['answer'] ?? '',
            'id' => $inputname,
        ];

        if ($options->readonly) {
            $inputattributes['readonly'] = 'readonly';
        }

        return html_writer::tag('div', $question->questiontext) .
               html_writer::empty_tag('input', $inputattributes);
    }
}
```

## Reference Implementations

| Plugin | Path | Pattern |
|--------|------|---------|
| Short Answer | `question/type/shortanswer/` | Text input |
| Multiple Choice | `question/type/multichoice/` | Options |
| Essay | `question/type/essay/` | Manual grading |

## References

See [Question Type Patterns](references/patterns.md) for detailed examples.
