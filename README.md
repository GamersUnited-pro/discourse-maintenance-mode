# Discourse Maintenance Mode Plugin

A simple Discourse plugin to enable a toggleable maintenance mode.

## Features

- Admin toggle to enable or disable maintenance mode  
- Customizable maintenance page title and message via site settings  
- Blocks all non-admin/moderator users from accessing most pages  
- Allows access to login and registration pages during maintenance  
- Lightweight and easy to configure  

## Installation

Note: This has been tested when running Discourse in a container.

### Method 1: Edit `app.yml` (recommended)

1. SSH into your server and open the Discourse container config:
   ```bash
   cd /var/discourse
   nano containers/app.yml
   ```
2. Under the `hooks:` → `after_code:` → `cmd:` section (where `docker_manager` is), add:
   ```bash
   - git clone --branch v1.0.11 https://github.com/GamersUnited-pro/discourse-maintenance-mode.git
   ```
   
   Example:
   ```bash
   hooks:
   after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/docker_manager.git
          - git clone --branch v1.0.11 https://github.com/GamersUnited-pro/discourse-maintenance-mode.git
   ```

3. Rebuild your container:
   ```bash
   echo "- git clone --branch v1.0.11 https://github.com/GamersUnited-pro/discourse-maintenance-mode.git" >> containers/app.yml && ./launcher rebuild app
   ```

### Method 2: Quick one-liner install
From `/discourse` (wherever you installed the Discourse container), run:
   ```bash
   echo "- git clone --branch v1.0.11 https://github.com/GamersUnited-pro/discourse-maintenance-mode.git" >> containers/app.yml && ./launcher rebuild app
   ```

### Usage
   - Enabled: All non-admin/moderator users see the maintenance page.
   - Disabled: Forum runs normally.
   - Custom Settings: Change the title and message shown on the maintenance page from Admin → Settings → Plugins.

### Notes
   - Admins and moderators can always access the site while maintenance mode is enabled.
   - Login, registration, and password reset pages remain available to users during maintenance.
