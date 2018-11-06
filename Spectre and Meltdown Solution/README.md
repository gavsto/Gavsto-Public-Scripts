# ConnectWise-Automate-Meltdown-and-Spectre-Detection-Scripts

  - Adapted Powershell Script to extract fields into EDFs within ConnectWise Automate. If you have problems generating the EDFs then import the XML twice.
  - Three registry add scripts thanks to @snix
  - Dataview contributed by @DarrenWhite99, with appreciation to #labtech-security in LabTechGeek Slack
  - Only the .XML is needed - this has the .PS1 included here attached within it.
  - This should work on any Machine with Powershell 2 or above.
  - Thank you to @kgrube and @Matthew for their significant input into this ReadMe

## Usage

1) Download the latest release from [here](https://github.com/gavsto/ConnectWise-Automate-Meltdown-and-Spectre-Detection-Scripts/releases/latest).
2) Import XML Scripts (Meltdown and Spectre - Detection ConnectWise Automate Script.xml)
   - Twice; if you're still having problems reload the system cache and try again
3) Import the SQL Dataview file (DATAVIEW - Spectre and Meltdown Assessment.sql). 
   - This will also trigger a rebuild of the computer EDF table which should help make EDF's available.
4) Reload System Cache, then verify EDFs have been created by opening an Agent, going to EDFs, going to the Meltdown and Spectre Detection Section.  Make sure EDFs are all there.
5) Run the script (by default, this imports into Scripts > Meltdown and Spectre Detection), against an agent, which will populate the EDFs

As per the attached license, THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. This exploit/bug is complex and multi-layered.

## Scripts

  | Script | Description | 
  | --- | --- |
  | Meltdown and Spectre - Detection ConnectWise Automate Script | Powershell script runner, populates EDFs |
  | Meltdown and Spectre - Enable Hyper-V Mitigations for VMs | Enable [Hyper-V Host mitigation](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/CVE-2017-5715-and-hyper-v-vms)  |
  | Meltdown and Spectre - Enable Local Mitigations | Enable [Local mitigation](https://support.microsoft.com/sq-al/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution) |
  | Meltdown and Spectre - Set Allow Reg Key for Update | Set [ALLOW REGKEY](https://support.microsoft.com/en-us/help/4056891) to allow patch to install |
 
    
## Extra Data Fields

  | Field | Description |
  | --- | --- |
  | Is The Machine Secure? | Will only tick when all other conditions are met and the machine is deemed secure | 
  | Suggested Actions | Output from powershell suggesting next actions |
  | Date of Last Run | Date the detection in the script last ran |
  | AV Key Set so Updates Can Occur | The registry key allowing for the MS updates to be detected is set so updates should detect when next scanned |
  | Hardware requires kernel VA Shadowing | This will be True for all CPU architecture vulnerable to Meltdown i.e. Intel.  It will show as False if not, i.e. on an AMD based system | 
  | Hardware Support for BTI Mitigation is Present | This indicates if the required firmware/bios update has occurred to expose the new MSR’s into OS. Without the firmware, no Spectre mitigations can be enabled. | 
  | Windows OS Support for BTI Mitigation is Enabled | Simple indicates if mitigation is active (True) or inactive (False). This will depend on the other settings and is not a configurable. | 
  | Windows OS Support for BTI Mitigation is Present | If true, the relevant security patch has been deployed. If false, the patch is missing or reboot has not taken place | 
  | Windows OS Support for Kernal VAShadow is Enabled | Will be True if the relevant registry keys have been “enabled” (post reboot), if not will show False. |
  | Windows OS Support for Kernal VAShadow is Present | Will be True if the relevant Microsoft Windows patch has been installed (post reboot). If patch has not been installed, it will be False. |
  | Windows Support for BTI Disabled by No Hardware | Will be True if no microcode update has been performed on the system. Microcode (firmware/bios) is required to add the relevant values relative to Meltdown |
  | Windows Support for BTI Disabled by System Policy | Will be True if the mitigation registry keys have been set to disable, otherwise should read false. |
  | Windows support for PCID optimization is enabled | Will only show once machine has been patched. PCID is not required in order for mitigations to work, but when present and active can help by reducing performance deg, though this is workload dependent. |
  
## Patches

  | Patch | Description | OS |
  | --- | --- | --- |
  | [KB4056897](https://support.microsoft.com/en-us/help/4056897/windows-7-update-kb4056897) | Security Only | Win7, Server 2008 R2 |
  | [KB4056894](https://support.microsoft.com/en-us/help/4056894) | Rollup | Win7, Server 2008 R2 |
  | [KB4056898](https://support.microsoft.com/en-us/help/4056898/windows-81-update-kb4056898) | Security Only | Win8.1, Server 2012 R2 |
  | [KB4056895](https://support.microsoft.com/en-us/help/4056895/windows-81-update-kb4056895) | Rollup | Win8.1, Server 2012 R2 |
  | [KB4056892](https://support.microsoft.com/en-us/help/4056892/windows-10-update-kb4056892) | Rollup | Win10 v1709 |
  | [KB4056891](https://support.microsoft.com/en-us/help/4056891) | Rollup | Win10 v1703 |
  | [KB4056890](https://support.microsoft.com/en-us/help/4056890/windows-10-update-kb4056890) | Rollup | Win10 v1607, Server 2016 |
  | [KB4056893](https://support.microsoft.com/en-us/help/4056893/windows-10-update-kb4056893) | Rollup | Win10 v1507 |
  | TBA |  | Server 2012 |
  | TBA |  | Server 2008 | 
  
## Further Reading
  
  - [CPU Vulnerability - Spectre / Meltdown Detection Solution](https://www.labtechgeek.com/topic/3984-cpu-vulnerability-spectre-meltdown-detection-solution/)
  - [ADV180002 | Guidance to mitigate speculative execution side-channel vulnerabilities](https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/ADV180002)
  - [Windows Server guidance to protect against speculative execution side-channel vulnerabilities](https://support.microsoft.com/en-us/help/4072698/windows-server-guidance-to-protect-against-the-speculative-execution)
  - [Windows Client Guidance for IT Pros to protect against speculative execution side-channel vulnerabilities](https://support.microsoft.com/en-us/help/4073119/protect-against-speculative-execution-side-channel-vulnerabilities-in)


