# k

## Overview

`k` is a command-line utility that integrates `kubectl` with `fzf`, offering a streamlined management experience for Kubernetes.

## Getting Started

To prepare for installation, first, create a `bin` directory in your home folder and include it in your system's PATH. This step ensures you can execute scripts and programs from this directory without the need to specify their full path. Execute the commands below to set this up:

```sh
mkdir -p ~/bin
echo 'export PATH="~/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

This process creates the bin directory if it's missing and adds it to the PATH variable in your `.bashrc` file, which configures the bash shell. To activate the changes, either restart your terminal session or source your `.bashrc` file.

## Prerequisites

You need to have the following tools installed before you can use this project:

- `kubectl`: The command-line tool for interacting with Kubernetes.
- `fzf`: A command-line utility for fuzzy finding.

Follow the installation instructions provided below if these tools are not already installed on your system.

## Installation

### `kubectl`

For installation instructions, visit: https://kubernetes.io/ja/docs/tasks/tools/install-kubectl/

```sh
curl -Lo ~/bin/kubectl "https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl"
chmod +x ~/bin/kubectl
```

### `fzf`

For more information, visit: https://github.com/junegunn/fzf

```sh
git clone --depth 1 https://github.com/junegunn/fzf.git ~/bin/.fzf
~/bin/.fzf/install
```

### `k`

To install, run the following:

```sh
git clone --depth 1 https://github.com/takahashi-jo/k.git ~/bin/k
chmod +x ~/bin/k
```

## Usage

To use the tool, simply execute:

```sh
. k
```

## License

This project incorporates tools that are distributed under various licenses:

- **kubectl**: A part of Kubernetes, available under the Apache License 2.0. You can find the license here: [https://github.com/kubernetes/kubernetes/blob/master/LICENSE](https://github.com/kubernetes/kubernetes/blob/master/LICENSE)
- **fzf**: Released under the MIT License. The license can be found here: [https://github.com/junegunn/fzf/blob/master/LICENSE](https://github.com/junegunn/fzf/blob/master/LICENSE)

Please review each tool's license for specific terms and conditions.