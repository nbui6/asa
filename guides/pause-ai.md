# Pause AI — close every way in, and open them again

**What it does.** It stops every AI from reaching your projects, on this laptop, until you resume. **The
app and your files keep working exactly as before.** Some steps the app does for you; the rest only you can
do, because they are in your Claude accounts. The app walks you through each one and ticks it when it can
see it's done.

## Pause

**The app does these (one click, *Pause AI*):**

1. Removes Asa's automatic checks (hooks) from Claude Code on this laptop.
2. Adds a rule to Claude Code's settings that refuses to read `projects\` and your private folder.
3. Removes Asa's skills from Claude Code on this laptop.
4. Writes `projects\.asa-paused`: any AI that still reads the instruction stops and says so.

**You do these (the app shows each, with a *Done* tick):**

5. **Claude desktop app:** Settings → the folder you connected → **Remove**. Do this in every Claude
   account you use on this laptop.
6. **Scheduled tasks:** in Claude, open **Scheduled tasks** → switch each one **off**.
7. **Skills on your accounts:** in Claude, **Settings → Skills** → turn off or remove `asa` and the others.
8. **GitHub:** if GitHub is linked to Claude, **Settings → Connectors → GitHub → Disconnect**.
9. **Optional:** delete old conversations you don't want kept.

> *The menu names in steps 5–8 are Claude's own and can change. Before this guide ships, they are checked
> against Claude's help pages, with the date here; the app links each step to that help page.*

## Resume

*Resume AI* undoes 1–4. The app then lists 5–8 again, the other way round, for you to switch back on.

**What pausing can't do:** take back what an AI already read in earlier conversations; those stay with the
AI provider for your account's retention period.
