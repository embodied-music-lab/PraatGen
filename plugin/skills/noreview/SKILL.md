---
name: noreview
description: "Skips the independent check before delivery. By default a fresh Opus reviewer checks every script against the code rules and clinical defaults; NOREVIEW is faster."
disable-model-invocation: true
---

Apply the PraatGen keyword NOREVIEW exactly as PraatGen's rules define it. If PraatGen isn't running in this conversation, start it first: load the praatgen skill with the Skill tool and follow its instructions, including the full read of its rules. Treat what follows as the user's message, typed after NOREVIEW: $ARGUMENTS
