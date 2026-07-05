# Dotfiles repo (home directory)

Home is the work tree of a bare git repo at `~/.dotfiles`. Operate on it with:

```bash
git --git-dir=$HOME/.dotfiles --work-tree=$HOME <cmd>
```

`status.showUntrackedFiles` is off; only explicitly tracked files show up.

## Claude window pinger

`claude-ping.timer` (09:00 / 14:00 / 19:00) runs `~/.local/bin/claude-ping.sh`,
which sends a minimal Haiku ping on **subscription auth** to anchor the rolling
5-hour usage window. Results go to `~/.claude/window-pinger/ping.log`; systemd
status alone is not enough, check the log.

Known failure mode and its fix:

- Headless `claude -p` cannot refresh an expired OAuth access token (8h TTL),
  so runs more than 8h after the last interactive session fail with
  `401 Invalid authentication credentials`
  ([claude-code#53063](https://github.com/anthropics/claude-code/issues/53063)).
  The 19:00 → 09:00 gap always triggers this.
- Fix in place since 2026-07-05: the script exports a long-lived token
  (`claude setup-token`) from `~/.claude/window-pinger/oauth-token`
  (chmod 600, untracked secret) as `CLAUDE_CODE_OAUTH_TOKEN`, which needs no
  refresh. Token expires ~yearly; current one issued Jul 2026, renew ~Jul 2027
  by re-running `claude setup-token` and overwriting that file.
- If pings 401 again: first check the token file exists and is not expired.
- Never set `ANTHROPIC_API_KEY` in the pinger or its unit; that bills the API
  per-token and does not touch the subscription window.
- `claude` is the native-installer binary at `~/.local/bin/claude`
  (npm-global install was removed 2026-07-04).
