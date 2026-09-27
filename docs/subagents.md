# Subagent Delegation

An agent gives a complex, specialized, or multi-step task to a subagent. Delegation
keeps one responsibility for each agent and a small context for the main agent.

## Triggers

If one of these conditions is true, give the task to a subagent:

1. **Domain:** The task needs special knowledge, for example code execution, a security
   audit, or database access.
2. **Context:** The task reads a large text or a large data stream. The main context
   does not need this data.
3. **Parallel work:** The task has independent parts. The parts can run at the same
   time.
4. **Step count:** One step of the workflow has more than three sequential operations.

## Workflow

1. Find a trigger in the request of the operator.
2. Select the subagent with the mandate that agrees with the task.
3. Write a prompt that contains all the context. Do not refer to the conversation.
4. Start the subagent with this prompt.
5. Examine the result of the subagent. Then add the result to the main context.

## Prompt

Put these parameters in the prompt of a subagent:

- **Goal:** The final output that you expect.
- **Input:** Only the data that the subagent needs for the task.
- **Constraints:** The rules, the prohibited actions, and the format rules.
- **Output format:** The exact structure of the response.

## Limits

- Before a subagent starts a subagent, set a limit that stops the loop.
- If a subagent fails or times out, return control to the main agent immediately.
- Do not give the system prompt to a subagent.
