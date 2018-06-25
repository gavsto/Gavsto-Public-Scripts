AUTHOR: Gavin Stone https://www.gavsto.com gavin@gavsto.com

CONTRIBUTORS: Ctaylor - http://labtechconsulting.com/

CONTRIBUTIOS: - Jaykul - https://github.com/Jaykul

USAGE:

Modify Line 1 to input your own logo: https://www.base64-image.de/

Parameters:
Paths: Can take multiple paths in either local format or UNC format

TrytorunaslocationAdmin: Performs the treesize as a location administrator

Displayunits: Either B,KB,MB,GB or TB 

Global Variables:
folderSizeFilterMinSize - Used in conjunction with folderSizeFilterDepthThreshold to excludes from the report sections of the tree that are smaller than a particular size.

folderSizeFilterDepthThreshold: Enables a folder size filter which, in conjunction with folderSizeFilterMinSize, excludes from the report sections of the tree that are smaller than a particular size.
folderSizeFilterDepthThreshold

Setting this parameter filters the number of files shown at each level.

topFilesCountPerFolder: For example, setting it to 10 will mean that at each folder level, only the largest 10 files will be displayed in the report. 
The count and sum total size of all other files will be shown as one item.