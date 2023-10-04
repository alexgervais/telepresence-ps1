# telepresence-ps1.sh -- Telepresence prompt for Zsh and Bash

## Description

This script lets you add the current [Telepresence](https://www.telepresence.io/) connection status and context
to your Zsh or Bash prompt.

Inspired by [kube-ps1](https://github.com/jonmosco/kube-ps1).

## Demo

![Demo](img/telepresence-ps1.gif)

## Installation from source

Download and source the script into your `~/.zshrc` or `~/.bashrc` file

### Zsh

```bash
git clone https://github.com/alexgervais/telepresence-ps1.git ~/telepresence-ps1

source ~/telepresence-ps1/telepresence-ps1.sh
PROMPT='$(telepresence_ps1)'$PROMPT
```

### Bash

```bash
git clone https://github.com/alexgervais/telepresence-ps1.git ~/telepresence-ps1

source ~/telepresence-ps1/telepresence-ps1.sh
PS1='[\u@\h \W $(telepresence_ps1)]\$ '
```

### Requirements

The script assumes you have the `telepresence` and `jq` binaries installed and executable from your `$PATH`.

- If you are only getting started with Telepresence, you'll find the necessary installation instruction steps
  here: https://www.telepresence.io/docs/latest/quick-start/
- You may install the `jq` utility following these instructions: https://jqlang.github.io/jq/download/

## Customization

The default settings can be overridden in `~/.zshrc` or `~/.bashrc` by setting the following environment variables:

| Variable                               | Default        | Description                                                                                               |
|----------------------------------------|----------------|-----------------------------------------------------------------------------------------------------------|
| `TELEPRESENCE_PS1_TELEPRESENCE_BINARY` | `telepresence` | Location of the `telepresence` binary. The script assumes it is available in your `$PATH` and executable. |
| `TELEPRESENCE_PS1_JQ_BINARY`           | `jq`           | Location of the `jq` binary. The script assumes it is available in your `$PATH` and executable.           |
| `TELEPRESENCE_PS1_SYMBOL_ENABLE`       | `true`         | Display the prompt symbol. If set to `false`, this will also disable `TELEPRESENCE_PS1_SEPARATOR`.        |
| `TELEPRESENCE_PS1_CONNECTION_ENABLE`   | `true`         | Display the connection status.                                                                            |
| `TELEPRESENCE_PS1_CONTEXT_ENABLE`      | `true`         | Display the context to which Telepresence is connected.                                                   |
| `TELEPRESENCE_PS1_PREFIX`              | `(`            | Prompt opening character.                                                                                 |
| `TELEPRESENCE_PS1_SUFFIX`              | `)`            | Prompt closing character.                                                                                 |
| `TELEPRESENCE_PS1_SEPARATOR`           | `\|`           | Separator between the symbol and status.                                                                  |
| `TELEPRESENCE_PS1_DIVIDER`             | `:`            | Separator between the connection status and context.                                                      |
| `TELEPRESENCE_PS1_SYMBOL_DEFAULT`      | `⧓`            | Default prompt symbol. Unicode `\u29D3`                                                                   |
| `TELEPRESENCE_PS1_SYMBOL_PADDING`      | `false`        | Adds a space (padding) after the symbol to prevent clobbering prompt characters                           |
| `TELEPRESENCE_PS1_SYMBOL_COLOR`        | `magenta`      | Set default color of the Telepresence symbol                                                              |
| `TELEPRESENCE_PS1_DISCONNECTED_COLOR`  | `red`          | Set default color of the disconnected status                                                              |
| `TELEPRESENCE_PS1_CONNECTED_COLOR`     | `magenta`      | Set default color of the connected status                                                                 |
| `TELEPRESENCE_PS1_CONTEXT_COLOR`       | `cyan`         | Set default color of the context                                                                          |
| `TELEPRESENCE_PS1_BG_COLOR`            |                | Set default color of the prompt background                                                                |

## License

This script is licensed under the [Apache License](LICENSE).
