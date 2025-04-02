# env-sync

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

**env-sync** is a versatile Bash utility designed for comparing, synchronizing, and managing environment variable files, commonly known as `.env` files.

This tool streamlines the maintenance of consistent environment configurations by enabling the comparison of source and target `.env` files.

It allows you to efficiently add missing variables and remove obsolete ones, ensuring a clean and organized setup.

## Features

- Compare .env files to identify differences
- Display variables present in source but missing in target
- Display variables present in target but obsolete in source
- Append missing variables from source to target
- Remove obsolete variables from target
- Sort variables alphabetically
- Configurable output verbosity
- Timestamp logging
- Support for first or last occurrence of duplicate variables

## Installation

Download script directly from [`GitHub`](https://raw.githubusercontent.com/zoltraks/env-sync/refs/heads/main/env-sync.sh) or clone repository.

```bash
# Download script directly
wget https://raw.githubusercontent.com/zoltraks/env-sync/refs/heads/main/env-sync.sh
```

```bash
# Clone the repository
git clone https://github.com/username/env-sync.git
```

```bash
# Make the script executable
chmod +x env-sync.sh
```

```bash
# Optionally create a symlink for global access
sudo ln -s $(pwd)/env-sync.sh /usr/local/bin/env-sync
```

## Usage

```
./env-sync.sh [options] source.env target.env [output.env]
```

### Arguments

- `source.env`: Source environment file used as reference
- `target.env`: Target environment file to compare against
- `output.env`: Output file for modified content (optional)

### Options

| Option       | Description |
|--------------|-------------|
| `--help`     | Show help message and exit |
| `--verbose`  | Print verbose messages |
| `--time`     | Add timestamps to log messages |
| `--last`     | Change mode to read the last occurrence of duplicate variables (default is first) |
| `--remove`   | Remove obsolete variables from target |
| `--append`   | Add missing variables from source to target |
| `--missing`  | Show only variables present in source but missing in target |
| `--obsolete` | Show variables present in target but not in source |
| `--sort`     | Sort variables alphabetically by name |

## Examples

### Display differences between two files

```bash
./env-sync.sh dev.env prod.env
```

### Show missing variables

```bash
./env-sync.sh --missing dev.env prod.env
```

### Show obsolete variables

```bash
./env-sync.sh --obsolete dev.env prod.env
```

### Add missing variables to target file

```bash
./env-sync.sh --append dev.env prod.env updated-prod.env
```

### Remove obsolete variables from target file

```bash
./env-sync.sh --remove dev.env prod.env updated-prod.env
```

### Synchronize files (add missing and remove obsolete)

```bash
./env-sync.sh --append --remove dev.env prod.env updated-prod.env
```

### Sort variables alphabetically

```bash
./env-sync.sh --sort dev.env prod.env
```

### Show verbose output with timestamps

```bash
./env-sync.sh --verbose --time dev.env prod.env
```

## Behavior

- Comments (lines starting with `#`) and empty lines are preserved
- Case-insensitive variable name comparison
- Variable values are preserved as-is, including spaces and quotes
- By default, the first occurrence of duplicate variables is used
- With `--last` option, the last occurrence of duplicate variables is used

## Use cases

- Synchronize development and production environment variables
- Check for missing configuration in deployment environments
- Keep template configuration files up-to-date
- Clean up obsolete configuration variables
- Document differences between environment configurations

## License

MIT License

## Contributing

Contributions are welcome!

Please feel free to submit a Pull Request.

## Acknowledgements

During the development of the script code, the assistance of various AI tools was utilized, including Microsoft Copilot, Anthropic Claude, and OpenAI GPT. Their contributions enhanced the efficiency and creativity of the project, enabling innovative solutions and precise implementation.

Project ASCII art was created using [Text to ASCII Art Generator](https://patorjk.com/software/taag/).
