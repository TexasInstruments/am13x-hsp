<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://www.ti.com/content/dam/ticom/images/identities/ti-brand/ti-logo-hz-1c-white.svg" width="300">
  <img alt="Texas Instruments Logo" src="https://www.ti.com/content/dam/ticom/images/identities/ti-brand/ti-hz-2c-pos-rgb.svg" width="300">
</picture>

# Embedded Coder Support Package for Texas Instruments AM13x Processors

This repository contains TI's Embedded Coder Support Package for AM13x processors, enabling Model-Based Design workflows for real-time control applications.

[Summary](#summary) | [Features](#features) | [Supported Devices](#supported-devices) | [Setup Instructions](#setup-instructions) | [Build Instructions](#build-instructions) | [Licensing](#licensing) | [Contributions](#contributions) | [Developer Resources](#developer-resources)
</div>

## Summary

Design models in Simulink, generate code using Embedded Coder, and run the executables on AM13x devices designed for real-time control applications without using manual programming. Apply industry-proven techniques for Model-Based Design to verify that the algorithms work during simulation and then implement the algorithms as standalone applications on the AM13x platforms using automatic code generation. By default, the generated code is ANSI/ISO C/C++.

## Features

- Code Replacement Library (CRL) for Trigonometric Math Unit (TMU)
- TI System Configuration Tool (SysConfig) integration
- TI CCS IDE project creation
- Processor-in-the-loop (PIL) with Profiling
- Monitor and tune (External mode)
- Hardware Interrupt block for custom interrupt handlers

**Supported Toolchains:**
- TI ARM Clang
- IAR

## Supported Devices

- [AM13E230x LaunchPad](https://www.ti.com/tool/LP-AM13E230)

## Setup Instructions

### Requirements:

| # | Name | Version | Download Links |
|---|------|---------|----------------|
| 1 | Code Composer Studio | 20.5.0 | https://www.ti.com/tool/download/CCSTUDIO/20.5.0 |
| 2 | TI-ARM-CLANG compiler | v4.0.4LTS | Included with CCS (e.g., ccs2050\ccs\tools\compiler\ti-cgt-armllvm_4.0.4.LTS) |
| 3 | IAR Embedded Workbench for Arm | 9.70.1 | https://updates.iar.com/?product=EWARM<br>[Patch](https://netstorage.iar.com/FileStore/STANDARD/001/004/200/ti_patch_AM13E230x_2_20260304.zip) if EWARM v9.70 or lesser |
| 4 | AM13E2X-SDK | 26_00_00_06 | https://www.ti.com/tool/download/AM13E2X-SDK/26.00.00.06.STS |
| 5 | TI System Configuration Tool | 1.27.0 | https://www.ti.com/tool/download/SYSCONFIG/1.27.0.4565 |
| 6 | MATLAB | R2025b or higher | https://www.mathworks.com/downloads |
| 7 | MinGW-w64 | 8.1+ (R2025b)<br>14.2+ (R2026a) | https://in.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-fortran-compiler |

**Note:** SysConfig/Syscfg will be used as an alias for TI System Configuration Tool in documentation.

### Installation Steps:

1. **Install Prerequisites:**

   **Code Composer Studio 20.5.0:**
   - Download CCS_20.5.0.00028_win.zip from https://www.ti.com/tool/download/CCSTUDIO
   - Extract and run `ccs_setup_20.5.0.00028.exe`
   - Use Installation Directory: `C:\ti\ccs2050`
   - Select Components: 'AM13x Arm-based microcontrollers'
   - Complete installation (approx. 10 mins)

   **AM13E2X SDK:**
   - Download `am13e230x_sdk_26_00_00_06_STS-windows-x64-installer.exe` from https://www.ti.com/tool/download/AM13E2X-SDK/26.00.00.06.STS
   - Run installer with Installation Directory: `C:\ti`
   - Complete installation (approx. 5 mins)

   **TI System Configuration Tool:**
   - Download `sysconfig-1.27.0_4565-setup.exe` from https://www.ti.com/tool/download/SYSCONFIG/1.27.0.4565
   - Run installer with Installation Directory: `C:\ti`

   **MATLAB/Simulink:**
   - Install R2025b or higher with: MATLAB Coder, Simulink Coder, Embedded Coder
   - Optional: Motor Control Blockset, Simscape, Simscape Electrical
   - Required: Embedded Coder Support Package for ARM Cortex-M Processors
   - Required: MinGW-w64 (for MEX compiler and make utility)

2. **Download HSP Package:**

   Choose one of the following methods:

   **Method 1: Download via MATLAB Add-On Explorer**
   - Open MATLAB
   - Click **Add-Ons** → **Get Hardware Support Packages**
   - In the Add-On Explorer window, use the 'Search for add-ons' field to search for 'AM13x'
   - From the dropdown, choose 'Embedded Coder Support Hardware Support Package for TI AM13x'
   - The add-on page will open
   - Click **Add** → **Download Only**
     > **Important:** Do NOT use **Add** → **Add to MATLAB (Download and add to path)**
   - Sign in using your MathWorks Account when prompted
   - Download the zip file

   **Method 2: Direct Download from MathWorks File Exchange**
   - In your browser, search Embedded Coder Hardware Support Package for TI AM13x and click on the first MathWorks link
   - The link should look like, https://in.mathworks.com/matlabcentral/fileexchange/{random-digits}-embedded-coder-hardware-support-package-for-ti-am13x with a random number in the place of {random-digits} inside the link.
   - Click **Download**
   - Sign in using your MathWorks Account when prompted
   - Download the zip file

   **Method 3: Download from GitHub**
   - Search 'am13x-hsp' on GitHub
   - Click on the repository under Texas Instruments' official account
   - Go to **Releases** and download the zip file
   - Alternatively, clone the repo or download zip of the main branch

   > **Note:** Depending on the download method, the folder name after extraction may vary. For consistency, we use `am13x-hsp-xxxxxxx` as the folder name in these instructions.

3. **Install HSP Package:**
   - Open MATLAB
   - Set **Preferences** → **MATLAB** → **Add-Ons** → **Installation Folder** to a path without spaces (e.g., `C:\workarea\AddOns`)
   - Extract the downloaded zip file to the installation folder (e.g., `C:\workarea\AddOns\am13x-hsp-xxxxxxx`)
   - In MATLAB, browse to the installed folder (e.g., `C:\workarea\AddOns\am13x-hsp-xxxxxxx`)
   - Run `hsp_am13x_setup` in the Command Window
   - A dialog box will prompt for paths of CCS, SDK, compiler, and SysConfig
   - Enter the paths or use the suggested defaults, then click **OK**
   - Verify the following logs appear in the Command Window:
     ```
     HSP AM13x setup...
     Path validation: Success!
     Installed TI ARM CLANG and IAR ARM toolchains!
     Setup complete! To get started, explore the example models in the /examples/ folder.
     ```

   **Note:** The paths you provide will be stored in `hsp_am13x_config.json` for future use. For CLI-based setup without dialog prompts, use `hsp_am13x_setup_cli` with optional named parameters. See [`hsp_am13x_setup_cli.m`](hsp_am13x_setup_cli.m) for details.

### Uninstall:

Run `hsp_am13x_uninstall` from MATLAB command window, then delete installation folder.

## Documentation
After downloading the package, click on TI_AM13X_HSP_USER_GUIDE.html file at the root level, or directly go to the doc\html\chapter_1_introduction\introduction_am13x.html path to open the detailed documentation

### Build Configuration
- Default: TI ARM Clang Compiler AM13x | gmake
- Optional: IAR ARM Compiler AM13x | gmake
- Configurations: Faster Builds, Faster Runs, Debug, Specify

### Key Features

**System Configuration Tool (SysConfig):**
Every Simulink model requires linked `.syscfg` file for hardware initialization code generation.

**Connectivity:**
Serial interface for PIL and External Mode. Configure in model settings.

**Debug in CCS:**
Import generated code: File → Import Projects → Browse to `{example_name}_ert_rtw/CCS_Project`

**PIL:**
Show numerical equivalence and profile code execution.
More info: https://in.mathworks.com/help/ecoder/ug/about-sil-and-pil-simulations.html

**External Mode:**
Real-time parameter tuning and signal monitoring.
More info: https://in.mathworks.com/help/ecoder/ug/external-mode-simulations-for-parameter-tuning-and-signal-monitoring.html

## Licensing

Please refer to the LICENSE file included with this package.

## Contributions

Please refer to the CONTRIBUTING file included with this package.


---
## Developer Resources
[TI E2E™ design support forums](https://e2e.ti.com) | [Learn about software development at TI](https://www.ti.com/design-development/software-development.html) | [Training Academies](https://www.ti.com/design-development/ti-developer-zone.html#ti-developer-zone-tab-1) | [TI Developer Zone](https://dev.ti.com/)