# Runs before the choco package is installed
# Copy pre installation files
$INSTALL_DIR =  Join-Path $PSScriptRoot 'installer'

cp "$PSScriptRoot\sdwresponse.properties" "$env:windir\temp\sdwresponse.properties" -Force
cp "$INSTALL_DIR\sid_files\SAS94_9CCLNB_70084773_Win_X64_Srv.txt" "$env:windir\temp\SAS94_9CCLNB_70084773_Win_X64_Srv.txt" -Force
<#
:: --------------------------------------------------------------------------------
:: This is a batch system requirements file created from order 9BVPLP at
:: 2019-02-15-15.52.28. The host was aef1e34a65114d0.cornell.edu and was running on a
:: Windows Server 2012 R2, version 6.3, 64-bit machine.
::
:: The following products were used to create this batch file:
::
:: SAS Deployment Tester - Client
:: SAS Enterprise Guide
:: SAS Enterprise Miner Workstation Configuration
:: SAS Foundation
::	â€¢ BASE Infrastructure to support Hadoop
::	â€¢ Base SAS
::	â€¢ GfK GeoMarketing CITIES Maps for SAS/GRAPH
::	â€¢ GfK GeoMarketing WORLD Maps for SAS/GRAPH
::	â€¢ SAS Accelerator Publishing Agent for Aster
::	â€¢ SAS Accelerator Publishing Agent for DB2
::	â€¢ SAS Accelerator Publishing Agent for Greenplum
::	â€¢ SAS Accelerator Publishing Agent for Hadoop
::	â€¢ SAS Accelerator Publishing Agent for Netezza
::	â€¢ SAS Accelerator Publishing Agent for Oracle
::	â€¢ SAS Accelerator Publishing Agent for SAP HANA
::	â€¢ SAS Accelerator Publishing Agent for Teradata
::	â€¢ SAS Clinical Standards Toolkit Framework
::	â€¢ SAS Data Quality Secure
::	â€¢ SAS Data Quality Server
::	â€¢ SAS Enterprise Miner
::	â€¢ SAS High-Performance Data Mining Server Components
::	â€¢ SAS High-Performance Econometrics Server Components
::	â€¢ SAS High-Performance Server
::	â€¢ SAS High-Performance Statistics Server Components
::	â€¢ SAS High-Performance Text Mining Server Components
::	â€¢ SAS Integration Technologies
::	â€¢ SAS LASR Analytic Server Access Tools
::	â€¢ SAS Network Algorithms
::	â€¢ SAS Scalable Performance Data Client
::	â€¢ SAS Text Analytics Common Components
::	â€¢ SAS Text Analytics for Spanish
::	â€¢ SAS Text Miner
::	â€¢ SAS/ACCESS Interface Products Samples
::	â€¢ SAS/ACCESS Interface to Amazon Redshift
::	â€¢ SAS/ACCESS Interface to Aster
::	â€¢ SAS/ACCESS Interface to DB2
::	â€¢ SAS/ACCESS Interface to Greenplum
::	â€¢ SAS/ACCESS Interface to HAWQ
::	â€¢ SAS/ACCESS Interface to Hadoop
::	â€¢ SAS/ACCESS Interface to Impala
::	â€¢ SAS/ACCESS Interface to Microsoft SQL Server
::	â€¢ SAS/ACCESS Interface to MySQL
::	â€¢ SAS/ACCESS Interface to Netezza
::	â€¢ SAS/ACCESS Interface to ODBC
::	â€¢ SAS/ACCESS Interface to OLE DB
::	â€¢ SAS/ACCESS Interface to Oracle
::	â€¢ SAS/ACCESS Interface to PC Files
::	â€¢ SAS/ACCESS Interface to PostgreSQL
::	â€¢ SAS/ACCESS Interface to SAP ASE
::	â€¢ SAS/ACCESS Interface to SAP HANA
::	â€¢ SAS/ACCESS Interface to SAP IQ
::	â€¢ SAS/ACCESS Interface to Teradata
::	â€¢ SAS/ACCESS Interface to Vertica
::	â€¢ SAS/ACCESS Interface to the PI System
::	â€¢ SAS/AF
::	â€¢ SAS/ASSIST
::	â€¢ SAS/CONNECT
::	â€¢ SAS/EIS
::	â€¢ SAS/ETS
::	â€¢ SAS/FSP
::	â€¢ SAS/GIS
::	â€¢ SAS/GRAPH
::	â€¢ SAS/GRAPH Obsolete Maps Data
::	â€¢ SAS/Genetics
::	â€¢ SAS/IML
::	â€¢ SAS/IntrNet
::	â€¢ SAS/OR
::	â€¢ SAS/QC
::	â€¢ SAS/SHARE
::	â€¢ SAS/STAT
:: SAS Integration Technologies Client
:: SAS ODS Graphics Designer
:: SAS Providers for OLE DB
:: SAS Studio - Single User
:: SAS Text Miner Workstation Configuration
:: SAS/GRAPH ActiveX Control
:: SAS/IML Studio
::
:: 1. Any entry listed as "(REQUIRED)" MUST be run to ensure the selected
::    products will install properly. For batch files created on 64-bit Windows,
::    there may be required entries that also reference 32-bit operating systems.
:: 2. Any entry listed as "(OPTIONAL)" is not needed for the selected products
::    but are required by other products in 9BVPLP. Optional entries may be
::    removed without affecting the installation of the selected products, but this
::    is NOT recommended.
:: 3. This batch file is only designed to run on machine(s) matching the operating
::    system on which it was created. To run the batch file on other machines, the
::    path to the executables below must be correct. To ensure the accuracy of this
::    batch file, the target depot should be in a location matching the paths in
::    this batch file rather than altering the paths in this batch file. If you must
::    use a different location, SAS recommends changing the SET variable rather than
::    the command for each requirement listed below.
::
#>
$DEPOT_HOME="$INSTALL_DIR\products"
<#
::
:: --------------------------------------------------------------------------------
:: Microsoft Office Access Database Engine 2010 (REQUIRED)

Start-Process "msiexec" -ArgumentList "/i $DEPOT_HOME\ace__99140__prt__xx__sp0__1\w32\native\AceRedist.msi /qn /norestart" -Wait
Start-Process "msiexec" -ArgumentList "/i $DEPOT_HOME\ace__99140__prt__xx__sp0__1\wx6\native\AceRedist_x64.msi /qn /norestart" -Wait

:: --------------------------------------------------------------------------------
:: Microsoft Runtime Components 2013 (REQUIRED)
#>
Start-Process "$DEPOT_HOME\vcredist2013__99150__prt__xx__sp0__1\w32\native\vcredist_x86.exe" -ArgumentList "/q /norestart" -Wait
Start-Process "$DEPOT_HOME\vcredist2013__99150__prt__xx__sp0__1\wx6\native\vcredist_x64.exe" -ArgumentList "/q /norestart" -Wait
<#
:: --------------------------------------------------------------------------------
:: Microsoft Runtime Components 2015 (REQUIRED)
#>
Start-Process "$DEPOT_HOME\vcredist2015__99130__prt__xx__sp0__1\w32\native\vc_redist.x86.exe" -ArgumentList "/q /norestart" -Wait
Start-Process "$DEPOT_HOME\vcredist2015__99130__prt__xx__sp0__1\wx6\native\vc_redist.x64.exe" -ArgumentList "/q /norestart" -Wait
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\FileRenameOperations" -Recurse -Force -ErrorAction SilentlyContinue
<#
:: --------------------------------------------------------------------------------
:: Microsoft.NET Framework 4.6 (REQUIRED)

Start-Process "$DEPOT_HOME\dotnet46__99110__prt__xx__sp0__1\w32\native\NDP46-KB3045557-x86-x64-AllOS-ENU.exe" -ArgumentList "/q /lang:ENU /norestart" -Wait
#>