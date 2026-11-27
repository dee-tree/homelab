# obsidian-livesync


## Backup

After backup restoration, **do not replicate DB** because it will overwrite the server state with the client state.
livesync has a versioning system that marks a client as 'a new version' while server after the backup restoration has an older version - so clients win.

**Use**: in the plugin settings, at *Maintenance*, choose "Reset synchronization at this device". This will take the server's state and ask about client-only files.
