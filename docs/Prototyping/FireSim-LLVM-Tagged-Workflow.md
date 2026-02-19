# FireSim + LLVM Tagged-Program Workflow (Repeatable)

This runbook captures the exact setup flow validated in this repository on **2026-02-19**.

## Scope

- Setup FireSim manager tooling in Chipyard library mode.
- Validate manager initialization for a local-FPGA style platform (`vitis`).
- Scaffold a VS Code + LLVM workflow for tagged Rocket programs with an FSM checker.

## Preconditions

- Repository root: `chipyard`
- Conda installed and on `PATH`
- `chipyard/env.sh` exists
- Network access for submodule and pip package download

## 1) Activate Chipyard environment

```bash
cd /home/michaeldoran/git/aberdeen/chipyard
export CONDA_NO_PLUGINS=true
source ./env.sh
```

If `conda` complains about an unsupported `libmamba` solver, run:

```bash
conda config --set solver classic
```

## 2) Initialize FireSim as a Chipyard library

```bash
./scripts/firesim-setup.sh
```

Expected behavior:
- Initializes nested FireSim submodules
- Generates `sims/firesim/env.sh`
- Prints `Setup complete!`

## 3) Install FireSim manager Python dependencies

In this environment, `firesim` required additional Python packages that were not preinstalled in `.conda-env`.

```bash
python -m pip install \
  argcomplete \
  boto3 \
  mypy-boto3-ec2 \
  mypy-boto3-s3 \
  fsspec \
  s3fs==0.4.2 \
  fab-classic>=1.19.2 \
  azure-mgmt-resourcegraph \
  pylddwrap \
  numpy
```

## 4) Validate FireSim manager startup

```bash
cd sims/firesim
source sourceme-manager.sh --skip-ssh-setup
cd deploy
firesim --help
```

`--skip-ssh-setup` is required unless `~/firesim.pem` exists.

## 5) Validate manager initialization

```bash
firesim managerinit --platform vitis
```

Expected output includes:
- `Running: managerinit`
- `Creating initial config files from examples.`
- `Adding default overrides to config files`

Run log location pattern:
- `sims/firesim/deploy/logs/<timestamp>-managerinit-<id>.log`

## 6) What this does and does not prove

This proves:
- FireSim manager CLI can start in this checkout
- FireSim config generation works for `vitis` platform mode

This does not yet prove:
- AWS F1 runfarm launch (`launchrunfarm`) without AWS credentials/config
- Bitstream build and workload execution on hardware

## 7) Optional AWS-specific manager setup

If using AWS F1 manager flow:

```bash
cd /home/michaeldoran/git/aberdeen/chipyard/sims/firesim
source sourceme-manager.sh
```

Requirements:
- `~/.aws/credentials` configured
- `~/firesim.pem` present and readable

## 8) Tagged LLVM VS Code plugin scaffold

A new scaffold is included at:
- `tools/vscode-rocket-tagged-llvm`

It provides:
- VS Code commands to compile tagged C into RISC-V asm/object via LLVM clang
- FSM tag-sequence checker script (`runtime/fsm-check.py`)
- sample tagged hello-world program (`examples/hello_tagged.c`)

See:
- `tools/vscode-rocket-tagged-llvm/README.md`
