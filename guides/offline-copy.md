# Offline copy — out of reach of any AI and any cloud

**What it is.** A copy of your projects and your private folder on a USB drive that is **unplugged**
almost all the time. The automatic backup protects you from mistakes; this protects you from losing the
laptop, and from anything that can reach a connected computer or a cloud.

**How often:** once a month, and before any big change. About five minutes.

## The first time

1. Get a USB drive (16 GB is plenty).
2. **Lock it with a password** (recommended): in File Explorer, right-click the drive → **Turn on
   BitLocker** → *Use a password* → save the recovery key somewhere safe but **not** on the laptop.
   (If your Windows edition or company policy doesn't offer BitLocker, skip this step and keep the drive
   somewhere safe.)

## Each time

1. Plug in the drive.
2. In the app: **Instruction for AI → AI access → Make an offline copy**, or run
   `kit\offline-copy.ps1`. It copies `projects\` and your private folder into a new folder named by date on
   the drive, checks that every file arrived, and says how many.
3. **Eject the drive** (the ⏏ icon in the taskbar, or right-click the drive → *Eject*) and unplug it.
4. The app shows *Offline copy: 28.09.2026*, and reminds you gently after a month.

Old copies stay on the drive until it's full; delete the oldest yourself when you need room.
