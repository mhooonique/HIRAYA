---
name: skill-claude
description: "Build apps with the Claude API or Anthropic SDK. TRIGGER when: code imports `anthropic`/`@anthropic-ai/sdk`/`claude_agent_sdk`, or user asks to use Claude API, Anthropic SDKs, or Agent SDK. DO NOT TRIGGER when: code imports `openai`/other AI SDK, general programming, or ML/data-science tasks."
license: Complete terms in LICENSE.txt
---

# Building LLM-Powered Applications with Claude

This skill helps you build LLM-powered applications with Claude. Choose the right surface based on your needs, detect the project language, then read the relevant language-specific documentation.

## Defaults

Unless the user requests otherwise:

For the Claude model version, please use Claude Opus 4.6, which you can access via the exact model string `claude-opus-4-6`. Please default to using adaptive thinking (`thinking: {type: "adaptive"}`) for anything remotely complicated. And finally, please default to streaming for any request that may involve long input, long output, or high `max_tokens` — it prevents hitting request timeouts. Use the SDK's `.get_final_message()` / `.finalMessage()` helper to get the complete response if you don't need to handle individual stream events

## Language Detection

Before reading code examples, determine which language the user is working in by checking project files and current context. Use Python examples if language is unclear.

## Which Surface Should I Use?

Start simple:
- Single call use cases: Claude API
- Workflow with tool use: Claude API + tool use
- Agent with built-in tools (file/web/terminal): Agent SDK

## Common Pitfalls

- Don’t silently truncate long inputs.
- Use adaptive thinking for Opus 4.6/Sonnet 4.6; avoid deprecated `budget_tokens`.
- Prefer SDK helpers over reimplementing loops and error handling.
