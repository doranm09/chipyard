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
cd /home/michaeldoran/git/chipyard
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
cd /home/michaeldoran/git/chipyard/sims/firesim
source sourceme-manager.sh
```

Requirements:
- `~/.aws/credentials` configured
- `~/firesim.pem` present and readable

## 8) Tagged LLVM VS Code plugin repository

The plugin is maintained as a standalone repository at:
- `/home/michaeldoran/git/vscode-rocket-tagged-llvm`

It provides:
- VS Code commands to compile tagged C into RISC-V asm/object via LLVM clang
- FSM tag-sequence checker script (`runtime/fsm-check.py`)
- sample tagged hello-world program (`examples/hello_tagged.c`)

See:
- `/home/michaeldoran/git/vscode-rocket-tagged-llvm/README.md`

## 9) Hardware Sideband Sink (Step 1 Integration)

To begin FireSim validation of hardware-side FSM checking, this branch adds a new Rocket-Chip MMIO peripheral:

- `freechips.rocketchip.devices.tilelink.FSMTraceSink`

The sink accepts 32-bit tag IDs over MMIO writes and performs transition checks in hardware against a programmable transition table.

### Enable in Chipyard config

Use:

- `chipyard.FSMTraceSinkRocketConfig`

This config enables:

- one Rocket core
- the `FSMTraceSink` peripheral at default base `0x10050000`

### Register map summary (`base = 0x10050000`)

- `0x00` control
  - bit 0: `enable`
  - bit 1: `enforceStart`
  - bit 2: write 1 to clear stats
  - bit 3: write 1 to clear transition table
- `0x04` `startId`
- `0x08` write tag ID (32-bit)
- `0x0c` status (`enable`, queue valid, seen-first, first-error-valid)
- `0x10` checked count
- `0x14` violation count
- `0x18` dropped-write count
- `0x1c` last tag
- `0x20` first error previous tag
- `0x24` first error current tag
- `0x28` transition program index (read)
- `0x2c` transition program index (write)
- `0x30` transition from tag
- `0x34` transition to tag
- `0x38` transition valid at current index (read bit 0)
- `0x3c` write 1 to program current transition entry
- `0x40` write 1 to clear current transition entry
- `0x44` transition from at current index (read)
- `0x48` transition to at current index (read)

### Software flow sketch

1. Program allowed transitions through index/from/to + commit registers.
2. Set `startId`.
3. Set `enable=1`.
4. Stream tag IDs by writing to `base + 0x08`.
5. Poll counters/status to detect violations.
