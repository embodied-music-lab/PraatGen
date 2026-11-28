"""Every phrase the build writes for the user to see or for Claude to say,
defined once. build_plugin.py imports it.

Approved text is used as Ian approved it. DRAFTS lists the new text that awaits
his approval; BUILD.md quotes each one under "Copy awaiting Ian".
"""

# ---- Approved ----
# The / menu text, and the introduction's tagline.
TAGLINE = ('Expert help with study design, measurement selection, and signal analysis '
           'for voice research and clinical measures in Praat.')
# The off command as the user is told to type it.
OFF_COMMAND = 'PRAATGEN OFF'
# What turning PraatGen off does (the introduction's off line, and the off command's / menu text).
OFF_EFFECT = ("I'll stop reading and applying my rules for the rest of this session, "
              'so ordinary conversation costs nothing extra.')
# How to turn PraatGen back on (the end of the introduction's off line).
BACK_ON = 'To turn me back on, type / and choose praatgen.'
# The introduction's opening line.
OFF_LINE = f'To turn PraatGen off, type {OFF_COMMAND} in any message. {OFF_EFFECT} {BACK_ON}'
# The line Claude gives a user who asks for work in PraatGen's areas while it isn't running.
SUGGESTION = ("PraatGen can help with this; start it by typing / and choosing praatgen, "
              "or tell me to go ahead without it.")
# The opening, when the first message already states the task: the line after the restatement,
# naming the step a yes goes straight to (approved 28 Nov 2026).
OFFER_TEMPLATE = "Say yes and I'll go straight to {}. To see the full introduction first, ask for it."
OFFER_LINE = OFFER_TEMPLATE.format('the PRE-FLIGHT')
# The same line when the first message also turns SCAFFOLD on (approved 28 Nov 2026).
SCAFFOLD_OFFER_LINE = OFFER_TEMPLATE.format('the scaffold discussion')
# The reply to a first message that is a question (approved 28 Nov 2026).
QUESTION_LINE = ('Would you like to build a script now? Or enter the scaffold command, '
                 'and we can just talk about it.')
# The plugin's description (plugin.json).
PLUGIN_DESCRIPTION = ('EML PraatGen as a Cowork skill: the PraatGen Master Prompt, its reference files '
                      'and its linter.')

# ---- DRAFT, awaiting Ian ----
# The opening's mark for an item of the restatement the user didn't give.
MISSING = 'missing'
# CONNECTED FOLDERS, when the session can't reach the user's computer. The control names
# come from Ian's own app, not Anthropic's documentation.
LINK_LINE = ('Linking this conversation to your computer lets me work with your folders directly. '
             'To link it, open the + menu in the message box, choose Devices, and pick your computer. '
             'The Claude desktop app has to be open on that computer.')

# The reply to the off command: "PraatGen is off." is new; the rest is BACK_ON.
OFF_REPLY = f'PraatGen is off. {BACK_ON}'
# The nointro command's / menu text: the introduction's NOINTRO row with "this" changed to "the".
NOINTRO_MENU = 'In your first message, skips the introduction.'

DRAFTS = (MISSING, LINK_LINE, OFF_REPLY, NOINTRO_MENU)
