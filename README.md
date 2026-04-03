<<<<<<< HEAD
![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg?style=for-the-badge)

# OwnCord

*The gaming chat platform you actually own.*

> **Early Alpha — Building in the Open**
> OwnCord is under active development and is not production-ready. Do not use it for sensitive communications. Security hardening is in progress. Contributions and [security reports](https://github.com/J3vb/OwnCord/issues) are welcome.

A self-hosted Windows chat platform with real-time messaging,
voice/video, file sharing, and a web admin panel. Run your own
server and keep everything under your control — zero cloud
dependencies, works fully on LAN.

<p align="center">
  <img src=".github/images/Client.png" alt="OwnCord Client" width="700">
</p>

<p align="center">
  <img src=".github/images/loginpage.png" alt="Login Page" width="340">
  <img src=".github/images/Admin_Panel.png" alt="Admin Panel" width="340">
</p>

## Features

### Chat

- Real-time text messaging over WebSocket
- Message editing, deletion, and replies
- Emoji reactions with per-message counts
- Typing indicators
- Full-text message search (SQLite FTS5)
- Pinned messages per channel
- Rich link previews with Open Graph metadata
- YouTube embed support with cached titles
- GIF picker powered by Tenor with inline rendering
- Inline image previews with lightbox viewer

### Voice & Video

- Voice channels powered by LiveKit SFU
- Webcam video chat with Discord-style grid layout (fixed 16:9 aspect ratio)
- Sidebar stream preview (hover to see live video thumbnail)
- Mute, deafen, camera, and screenshare controls
- Push-to-talk with global hotkey (non-consuming, works while unfocused)
- Per-user volume control (right-click user in voice channel)
- RNNoise ML noise suppression
- Voice activity detection with speaker indicators (pulsing green glow)
- Connection quality indicator with expandable transport stats
- Voice call duration timer (MM:SS / HH:MM:SS elapsed)
- LiveKit server runs as a companion process alongside `chatserver.exe`

### Direct Messages

- One-on-one DM conversations with any server member
- DM preview section in sidebar with unread bubble indicators
- Auto-reopen DM channels on incoming message
- DM header shows `@ username` with live online status

### Channels & Organization

- Text and voice channels organized by categories
- Create, edit, delete, and reorder channels
- Unread message indicators
- Quick channel switcher (Ctrl+K)

### File Sharing

- Drag-and-drop and clipboard paste uploads
- Inline image previews with persistent caching (IndexedDB)
- File download with native save dialog
- Configurable max upload size

### Users & Permissions

- Invite-only registration with invite codes
- Role-based permissions with custom roles
- Member list with online/offline presence
- User profiles with status (online, idle, dnd, offline)

### Administration

- Web-based admin panel at `/admin` (IP-restricted to private networks by default)
- Dashboard with server stats and recent activity
- User management (ban, kick, role assignment) with modals
- Channel management (create, edit, delete)
- Settings management (server name, MOTD, limits, security)
- Live server log streaming via SSE with level filters,
  search, auto-scroll, pause/resume, copy, and clear
- Audit log with search, action type filter, copy, and CSV export
- Database backup and restore with pre-restore safety backups
- Server update checker and one-click apply (GitHub Releases)
- Metrics endpoint with uptime, goroutines, heap, connected users
- Diagnostics endpoint for connectivity checks

### Security

- TLS encryption (self-signed, Let's Encrypt, or custom cert)
- Trust-on-first-use certificate pinning in the client
- Two-factor authentication (TOTP) with QR enrollment and backup codes
- Ed25519-signed client auto-updates
- Rate limiting on all endpoints
- CSRF protection and security headers
- Account deletion with password confirmation and data anonymization

### Desktop Client

- Native Windows app built with Tauri v2
- System tray integration
- Desktop notifications with taskbar flash and sound
- In-app auto-update with progress notification
- Credential storage via Windows Credential Manager
- Auto-login with saved credentials (one-click connect)
- Custom emoji picker
- Compact mode for information-dense layouts
- Discord-style settings panel with blurred backdrop
- OC Neon Glow theme with custom theming system (JSON import/export)
- Accent color picker
- Quick-switch server overlay for multi-server users
- Structured logging with JSONL persistence (5-day rotation)

## Quick Start

1. Download `chatserver.exe` and the OwnCord installer from
   [GitHub Releases](https://github.com/J3vb/OwnCord/releases)
2. Run `chatserver.exe` — generates `config.yaml` and a `data/`
   directory (database, TLS certs, uploads, backups) on first run
3. Open `https://localhost:8443/admin` to create the Owner account
4. Generate an invite code in the admin panel and share it
5. Friends install the client, enter your server address
   (`ip:8443`), and register with the invite code

The client uses TOFU (Trust On First Use) for self-signed
certificates — it prompts to trust the server on first
connection, then pins it for future sessions.

### Voice & Video Setup (Optional)

Voice and video require [LiveKit Server](https://github.com/livekit/livekit/releases):

1. Download `livekit-server` from the LiveKit releases page
2. Edit `config.yaml` and set:
   ```yaml
   voice:
     livekit_api_key: "devkey"           # any string
     livekit_api_secret: "secret-min-32-characters-long!!"  # min 32 chars
     livekit_binary: "C:/path/to/livekit-server.exe"
   ```
3. Restart `chatserver.exe` — it auto-starts LiveKit as a
   companion process

### Networking

For friends outside your LAN, you need to forward these ports:

| Port | Protocol | Purpose |
| ---- | -------- | ------- |
| `8443` | TCP | HTTPS, WebSocket, REST API |
| `7881` | TCP | LiveKit signaling (voice/video) |
| `50000-60000` | UDP | LiveKit WebRTC media (voice/video) |

Alternatively, use Tailscale for zero-config networking
with no port forwarding.

## Architecture

Two components: a **Go server** and a **Tauri v2 client**
(Rust + TypeScript).

```text
+---------------------+         +---------------------+
|   OwnCord Client    |         |   OwnCord Server    |
|   (Tauri v2)        |         |       (Go)          |
|                     |         |                     |
|  +---------------+  |  WSS    |  +---------------+  |
|  |  Chat UI      |--+------->|  |  WebSocket Hub|  |
|  +---------------+  |         |  +---------------+  |
|  +---------------+  |  HTTPS  |  +---------------+  |
|  |  REST Client  |--+------->|  |  REST API     |  |
|  +---------------+  |         |  +---------------+  |
|  +---------------+  | LiveKit |  +---------------+  |
|  |  Voice/Video  |--+------->|  |  LiveKit SFU  |  |
|  +---------------+  |         |  +---------------+  |
+---------------------+         |  +---------------+  |
                                |  |  SQLite DB    |  |
                                |  +---------------+  |
                                +---------------------+
```

- **WebSocket** — chat messages, typing, presence, voice signaling
- **REST API** — message history, file uploads, channel management, auth
- **LiveKit** — voice and video via LiveKit SFU (companion process)

## Project Structure

```text
OwnCord/
├── Server/                  # Go server
│   ├── api/                 #   REST handlers + middleware
│   ├── ws/                  #   WebSocket hub + handlers
│   ├── db/                  #   SQLite queries + migrations
│   ├── auth/                #   Authentication + rate limiting
│   ├── config/              #   YAML config loading
│   ├── updater/             #   GitHub Releases update checker
│   ├── admin/               #   Web admin panel (static SPA)
│   ├── storage/             #   File upload storage
│   ├── permissions/         #   Role-based permission system
│   └── migrations/          #   Database migration files
├── Client/
│   └── tauri-client/        # Tauri v2 desktop client
│       ├── src-tauri/       #   Rust backend (plugins, commands)
│       ├── src/             #   TypeScript frontend
│       │   ├── lib/         #     Core services (API, WS, LiveKit, updater)
│       │   ├── stores/      #     Reactive state (auth, channels, messages, voice)
│       │   ├── components/  #     UI components (28 modules)
│       │   ├── pages/       #     Page layouts
│       │   └── styles/      #     CSS
│       └── tests/           #   Unit, integration, and E2E tests
└── docs/                    # Project documentation (Obsidian vault)
```

## Building from Source

### Prerequisites

- Go 1.25+
- Node.js 20+
- Rust (stable)
- Windows 10/11

### Server

```bash
cd Server
go build -o chatserver.exe -ldflags "-s -w -X main.version=1.0.0" .
```

### Client

```bash
cd Client/tauri-client
npm install
npm run tauri build
```

The installer is output to
`Client/tauri-client/src-tauri/target/release/bundle/nsis/`.

### Running Tests

```bash
# Server
cd Server && go test ./...
cd Server && go test ./... -cover   # with coverage

# Client
cd Client/tauri-client
npm test                    # all tests (vitest)
npm run test:unit           # unit tests only
npm run test:integration    # integration tests
npm run test:e2e            # Playwright E2E (mocked Tauri)
npm run test:e2e:native     # Playwright E2E (real Tauri exe + CDP)
npm run test:coverage       # coverage report

# Type checking & linting
npm run typecheck           # full typecheck
npm run lint                # ESLint check
npm run lint:fix            # ESLint auto-fix
```

## Configuration

The server generates a `config.yaml` on first run. All runtime data
is stored in a `data/` directory alongside the executable:

```text
data/
├── owncord.db         # SQLite database
├── certs/             # TLS certificates (auto-generated if self_signed)
├── uploads/           # User-uploaded files
└── backups/           # Database backups
```

Key settings:

| Setting | Default | Description |
| ------- | ------- | ----------- |
| `server.port` | `8443` | HTTPS port |
| `server.name` | `OwnCord Server` | Display name |
| `tls.mode` | `self_signed` | TLS mode (self_signed, acme, manual, off) |
| `upload.max_size_mb` | `100` | Max upload size |
| `voice.livekit_url` | `ws://localhost:7880` | LiveKit server WebSocket URL |
| `voice.livekit_api_key` | — | LiveKit API key (required for voice) |
| `voice.livekit_api_secret` | — | LiveKit API secret (min 32 chars, required for voice) |
| `voice.livekit_binary` | — | Path to `livekit-server` binary (empty = don't auto-start) |
| `voice.quality` | `medium` | Voice quality (low, medium, high) |
| `server.admin_allowed_cidrs` | private nets | CIDRs allowed to access `/admin` |
| `github.token` | — | Token for update checks (optional, for higher rate limits) |

## Auto-Updates

The client checks for updates after connecting to the server.
Updates are Ed25519-signed and verified before install.

To enable signed releases in CI, add these GitHub repository secrets:

- `TAURI_SIGNING_PRIVATE_KEY` — Ed25519 private key
  (via `npx tauri signer generate`)
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` — key password

## Documentation

- [Quick Start Guide](docs/quick-start.md)
- [Server Configuration](docs/server-configuration.md)
- [LiveKit Setup (Voice/Video)](docs/livekit-setup.md)
- [Deployment Guide](docs/deployment.md)
- [Port Forwarding](docs/port-forwarding.md)
- [Tailscale Guide](docs/tailscale.md)
- [REST API Reference](docs/api.md)
- [WebSocket Protocol](docs/protocol.md)
- [Database Schema](docs/schema.md)
- [Client Architecture](docs/client-architecture.md)
- [Contributing](docs/contributing.md)
- [Security Policy](docs/security.md)

## Contributing

1. Fork the repo and create a feature branch from `dev`
2. Follow existing code style and conventions
3. Write tests for new functionality
4. Open a PR against `dev` with a clear description

See [Contributing Guide](docs/contributing.md) for details.

## Tech Stack

| Component | Technology |
| --------- | --------- |
| Server | Go, chi router, LiveKit server SDK |
| Database | SQLite (pure Go, embedded) |
| Client | Tauri v2 (Rust + TypeScript) |
| Voice/Video | LiveKit SFU (companion process) |
| Build | NSIS installer, GitHub Actions CI |

## License

AGPL-3.0
=======
# OwnCord



## Getting started

To make it easy for you to get started with GitLab, here's a list of recommended next steps.

Already a pro? Just edit this README.md and make it your own. Want to make it easy? [Use the template at the bottom](#editing-this-readme)!

## Add your files

* [Create](https://docs.gitlab.com/user/project/repository/web_editor/#create-a-file) or [upload](https://docs.gitlab.com/user/project/repository/web_editor/#upload-a-file) files
* [Add files using the command line](https://docs.gitlab.com/topics/git/add_files/#add-files-to-a-git-repository) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin http://gitlab.local/root/owncord.git
git branch -M main
git push -uf origin main
```

## Integrate with your tools

* [Set up project integrations](http://gitlab.local/root/owncord/-/settings/integrations)

## Collaborate with your team

* [Invite team members and collaborators](https://docs.gitlab.com/user/project/members/)
* [Create a new merge request](https://docs.gitlab.com/user/project/merge_requests/creating_merge_requests/)
* [Automatically close issues from merge requests](https://docs.gitlab.com/user/project/issues/managing_issues/#closing-issues-automatically)
* [Enable merge request approvals](https://docs.gitlab.com/user/project/merge_requests/approvals/)
* [Set auto-merge](https://docs.gitlab.com/user/project/merge_requests/auto_merge/)

## Test and Deploy

Use the built-in continuous integration in GitLab.

* [Get started with GitLab CI/CD](https://docs.gitlab.com/ci/quick_start/)
* [Analyze your code for known vulnerabilities with Static Application Security Testing (SAST)](https://docs.gitlab.com/user/application_security/sast/)
* [Deploy to Kubernetes, Amazon EC2, or Amazon ECS using Auto Deploy](https://docs.gitlab.com/topics/autodevops/requirements/)
* [Use pull-based deployments for improved Kubernetes management](https://docs.gitlab.com/user/clusters/agent/)
* [Set up protected environments](https://docs.gitlab.com/ci/environments/protected_environments/)

***

# Editing this README

When you're ready to make this README your own, just edit this file and use the handy template below (or feel free to structure it however you want - this is just a starting point!). Thanks to [makeareadme.com](https://www.makeareadme.com/) for this template.

## Suggestions for a good README

Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Badges
On some READMEs, you may see small images that convey metadata, such as whether or not all the tests are passing for the project. You can use Shields to add some to your README. Many services also have instructions for adding a badge.

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Installation
Within a particular ecosystem, there may be a common way of installing things, such as using Yarn, NuGet, or Homebrew. However, consider the possibility that whoever is reading your README is a novice and would like more guidance. Listing specific steps helps remove ambiguity and gets people to using your project as quickly as possible. If it only runs in a specific context like a particular programming language version or operating system or has dependencies that have to be installed manually, also add a Requirements subsection.

## Usage
Use examples liberally, and show the expected output if you can. It's helpful to have inline the smallest example of usage that you can demonstrate, while providing links to more sophisticated examples if they are too long to reasonably include in the README.

## Support
Tell people where they can go to for help. It can be any combination of an issue tracker, a chat room, an email address, etc.

## Roadmap
If you have ideas for releases in the future, it is a good idea to list them in the README.

## Contributing
State if you are open to contributions and what your requirements are for accepting them.

For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.

You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## Authors and acknowledgment
Show your appreciation to those who have contributed to the project.

## License
For open source projects, say how it is licensed.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
>>>>>>> 18f71e690a213e9847d568b5be4dfd1c34b7611a
