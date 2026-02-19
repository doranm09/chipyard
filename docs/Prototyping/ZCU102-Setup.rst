ZCU102 Setup Checklist
======================

This checklist captures the practical setup sequence for building the ZCU102
Rocket FPGA target in this repository.

Prerequisites
-------------

1. Linux host with Conda installed.
2. Vivado installed (expected path in this repo: ``/opt/Xilinx/2025.1/Vivado``).
3. Access to internal GitLab submodules:

   * ``git@gitlab.dornerworks.com:usarmy-aberdeen_sbir/fpga/fpga-shells.git``
   * ``git@gitlab.dornerworks.com:usarmy-aberdeen_sbir/generators/rocket-chip.git``

Repository Bootstrap
--------------------

1. Ensure GitLab SSH is working:

   .. code-block:: shell

      ssh -T git@gitlab.dornerworks.com

2. Run setup once (lean mode skips FireSim/FireMarshal):

   .. code-block:: shell

      source "$(conda info --base)/etc/profile.d/conda.sh"
      conda activate base
      ./build-setup.sh riscv-tools --use-lean-conda --skip-clean

3. If setup aborts during precompile, finish CIRCT install step only:

   .. code-block:: shell

      source ./env.sh
      ./build-setup.sh riscv-tools --use-lean-conda -s 1 -s 2 -s 3 -s 4 -s 5 -s 6 -s 7 -s 8 -s 9 -s 11

Environment Activation
----------------------

Use the helper script:

.. code-block:: shell

   source scripts/sourceme-zcu102.sh

Equivalent manual commands:

.. code-block:: shell

   source ./env.sh
   source /opt/Xilinx/2025.1/Vivado/settings64.sh

Sanity Checks
-------------

.. code-block:: shell

   which sbt
   which riscv64-unknown-elf-gcc
   which firtool
   which vivado
   vivado -version

Internal Submodule Sync
-----------------------

If submodules drift or were previously checked out from public mirrors:

.. code-block:: shell

   git submodule sync fpga/fpga-shells generators/rocket-chip
   git submodule update --init --recursive fpga/fpga-shells generators/rocket-chip

If a submodule worktree appears empty with many staged deletions, repair it:

.. code-block:: shell

   git -C generators/rocc-acc-utils reset --hard HEAD
   git -C generators/bar-fetchers reset --hard HEAD
   git -C tools/firrtl2 reset --hard HEAD

Build Targets
-------------

1. Elaborate/generate RTL and collateral:

   .. code-block:: shell

      cd fpga
      make SUB_PROJECT=zcu102 verilog -j8

2. Build bitstream:

   .. code-block:: shell

      cd fpga
      make SUB_PROJECT=zcu102 bitstream -j8

Serial Bootstrap Flow
---------------------

After programming the FPGA, reset starts from the BootROM region at ``0x10000``
and runs ``sdboot``. The sequence is:

1. Enable UART TX (MMIO UART at ``0x64000000``), then print ``INIT``.
2. Initialize SD in SPI mode.
3. Read payload from SD sector ``34`` (hardcoded) into RAM at ``0x80000000``.
4. Print ``BOOT`` and jump to ``0x80000000``.

Smoke Test SD Payload (Hello World)
-----------------------------------

Build the payload:

.. code-block:: shell

   source scripts/sourceme-zcu102.sh
   make -C fpga/src/main/resources/zcu102/tests clean bin

Preview flash command (safe dry run):

.. code-block:: shell

   ./scripts/zcu102-smoketest-sd.sh --target /dev/sdX --seek-sectors 34

Flash to SD (writes raw sector 34 on the device):

.. code-block:: shell

   ./scripts/zcu102-smoketest-sd.sh --target /dev/sdX --seek-sectors 34 --write

If you already created a partition that starts at sector 34, write at partition
offset 0 instead:

.. code-block:: shell

   ./scripts/zcu102-smoketest-sd.sh --target /dev/sdX1 --seek-sectors 0 --write

Connect to UART (adjust tty as needed):

.. code-block:: shell

   ls /dev/ttyUSB*
   screen -S ZCU102_UART /dev/ttyUSB1 115200

Expected serial output includes: ``INIT``, ``LOADING ...``, ``BOOT``, and
``Hello from payload at 0x80000000!``.

Notes
-----

* The warning below from Vivado settings has been non-fatal in this environment:

  ``/opt/Xilinx/2025.1/Vivado/settings64.sh: ... /opt/Vivado/DocNav/.settings64-DocNav.sh: No such file or directory``

* Bitstream generation can still fail on missing Vivado license features even
  when environment setup is correct.
