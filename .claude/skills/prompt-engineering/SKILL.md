---
name: prompt-engineering
description: >-
  Transform vague requests into effective 6-component prompts.
  Use when crafting prompts for AI agents, writing plan files,
  delegating tasks, or when Claude's responses miss the mark.
  Covers role, goal, context, format, examples, and constraints.
  Do NOT use for direct code implementation or testing.
metadata:
  author: Geoff
  version: 1.0.0
---

# Prompt Engineering

Transform vague requests into effective, actionable prompts using the 6-component framework.

## Instructions

### Step 1: Identify Missing Components

Check the prompt against the 6-component checklist:
1. **Role or Persona** - Who the AI should be
2. **Goal / Task Statement** - Exactly what you want done
3. **Context or References** - Key data the model needs
4. **Format or Output Requirements** - How you want the answer
5. **Examples or Demonstrations** - Show, don't just tell
6. **Constraints / Additional Instructions** - Boundaries that improve quality

Missing 3+ items? Rewrite the prompt.

### Step 2: Rewrite with All Components

Transform the vague request into a structured prompt with all 6 components present. Be concise but complete.

### Step 3: Apply to Plan Files

All files in `prompts/claude-comm/` should follow this structure:
```markdown
## Role
You are a [specific role with relevant expertise].

## Goal
[Specific, measurable task with clear success criteria]

## Context
- Current state, problem, constraints, file references

## Output Format
[Specify structure: numbered steps, code blocks, etc.]

## Examples
[Concrete examples of what you want]

## Requirements
- [Specific constraints]
```

## Examples

### Example 1: SwiftUI Feature Request

**Ineffective**: "Add glass effect to the cards."

**Effective**:
```
Role: Senior SwiftUI engineer with watchOS and Liquid Glass expertise.

Task: Add glass effect modifier to PhaseCardView with backward compatibility.

Context:
- WLGlassModifier exists in DesignSystem/Modifiers/
- Must support watchOS 11+ (fallback) and watchOS 26+ (native glass)
- Cards display phase info within LayerView's horizontal scroll

Format: Swift code with @available checks. Include test.

Constraints:
- Follow WL prefix convention
- View extension pattern: .wlGlass()
- File must be <= 200 lines
```

## Troubleshooting

### Error: AI responses are too vague or miss the mark
- Add concrete examples showing exactly what good output looks like
- Specify the output format explicitly
- Add constraints to narrow the scope
