# Analysis of file shares

The script makes it possible to analyze the file shares present on a Windows machine (i.e. File Server) in order to obtain recursively for each share the permissions, size and last access of each folder contained.

The `File-Share-Analysis.ps1` script creates a `shares-to-analyze.csv` file containing the shares found automatically and asks the user, before starting, to modify it depending on which shares are to be analyzed. It is possible to define the depth with which the script will explore each share:

Example:
With a tree of folders within the D:\ share like this:

```bash
D:\
├───anothertest
│   └───anothersub
└───test
    └───subtest
        └───subsubtest
            └───subsubsubtest
```
 

And the shares-to-analyze.csv file defined like this:
```
Name,Path,Depth
D$,D:\,2
```

the script will extract the information up to level 2 so the ACLs of the folders: anothertest, test, anothersub and subtest.

## Backward compatibility
            
The script was developed using the Powershell 2.0 API so that it is also compatible with older systems such as Windows Server 2008 R2.
