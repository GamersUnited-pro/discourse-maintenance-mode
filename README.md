# Discourse Maintenance Mode Plugin

A simple Discourse plugin to enable a toggleable maintenance mode.

## Features

- Admin toggle to enable or disable maintenance mode  
- Customizable maintenance page title and message via site settings  
- Blocks all non-admin/moderator users from accessing most pages  
- Allows access to login and registration pages during maintenance  
- Lightweight and easy to configure

## Installation

Note: This has been tested when running Discourse in a container

1. Edit your app.yaml:
   ```bash
   cd discourse
   nano containers/app.yaml

   --- Add below under cmd: in plugin section ---
   - git clone --branch v1.0.5 https://github.com/GamersUnited-pro/discourse-maintenance-mode.git
4. Rebuild your container
   ```bash
   ./launcher rebuild app
