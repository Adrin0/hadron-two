# Claude Tips and Skills Guide

## Purpose
This guide provides practical tips for using Claude effectively, along with a brief overview of common Claude skills and how to apply them.

---

## General Tips for Prompting Claude

1. Be clear and specific.
   - Use direct instructions and explicit goals.
   - Example: "Summarize the main points of this text in 3 bullets." rather than "Tell me about this."

2. Provide context.
   - Include relevant background so Claude can answer accurately.
   - If you are working on code, mention the language, framework, or file names.

3. Use step-by-step requests.
   - When a task is complex, ask Claude to break it into phases.
   - Example: "First identify issues, then suggest fixes, then write the updated code."

4. Ask for the format you want.
   - Specify whether you want bullets, tables, code blocks, summaries, or plans.
   - Example: "Return the answer as a numbered list."

5. Keep the model on task.
   - If the response drifts, prompt it to focus on the main question again.
   - Example: "Focus only on the compatibility issues between macOS and Linux."

---

## Best Practices for Code and Debugging

- Share only the relevant code sections.
- Mention the error message or failing behavior explicitly.
- Ask for tests or validation steps when you want to verify a fix.
- Use a consistent style for naming, formatting, and comments.
- If you want an explanation, request it separately from the code change.
  - Example: "Explain why this fix works in two sentences."

---

## Effective Use of Claude Skills

Claude skills are specialized capabilities that help with targeted tasks.

### Common Skill Types

- **Summarization**
  - Use for condensing text, meeting notes, or design docs.
  - Prompt example: "Summarize this documentation in plain language."

- **Code Review**
  - Use for auditing code, ensuring best practices, and finding bugs.
  - Prompt example: "Review this function and identify any issues or improvements."

- **Refactoring**
  - Use when you want cleaner, more maintainable code.
  - Prompt example: "Refactor this component to reduce duplication and improve readability."

- **Troubleshooting**
  - Use for diagnosing errors or unexpected behavior.
  - Prompt example: "I have this error output; what is the likely cause and how do I fix it?"

- **Learning and Explanation**
  - Use when you want concepts clarified or code behavior explained.
  - Prompt example: "Explain how this function works and why the `async` keyword is used."

---

## Suggested Prompt Patterns

1. Problem + context + desired result
   - "I have a React component that fails to render on mobile. Here is the code. Suggest fixes and explain the root cause."

2. Task + constraints
   - "Update this SQL query for Postgres compatibility and keep the same output columns."

3. Role + instruction
   - "Act as a senior DevOps engineer and recommend a secure deployment approach for a Kubernetes cluster."

4. Iterative improvement
   - "List the issues, then propose an improved version, then compare the two."

---

## Claude Skill Usage Tips

- Use the skill when you need a specialized outcome, such as summarization or code conversion.
- Keep prompts focused on the desired skill.
- If the model does not use the requested skill, restate the skill explicitly.
- Combine skills when needed: "Summarize this design doc, then identify risks, then suggest mitigation." 

---

## Quick Reference

- Use simple, explicit language.
- Provide examples and relevant values.
- Ask for output structure.
- Request a short summary at the end.
- Keep follow-up prompts narrow.

---

## Notes

This guide is a general resource for working with Claude in a development or collaboration environment. Adjust prompt style to your use case and workflow.
