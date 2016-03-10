# Git Plugin for Studio

[InterSystems Caché](http://www.intersystems.com/our-products/cache/cache-overview/) Studio plugin to use Git.

## Installation
* Clone repository or just download latest version into a local directory
```
git clone https://github.com/intersystems-ib/cache-git-studio.git
```

* Open a Terminal session in Cache
* Switch to a namespace where you want to use Git source control
```
zn "ENSEMBLE"
```

* Load and compile the downloaded source code in the first step 
```
set path="C:\Temp\cache-iat-pubsub\cache"
do $system.OBJ.ImportDir(path,"*.xml","ck",.error,1)
```

* Configure local paths for Git source control in the *^GITConfig* global:
```
ENSEMBLE>set ^GITConfig("gitpath")="c:\git\bin\"               // path to git binaries
ENSEMBLE>set ^GITConfig("workdir")="c:\workspace\MyProject\"   // path to git work directory
ENSEMBLE>set ^GITConfig("output")="c:\git.output.txt"          // temp. file to store git output
ENSEMBLE>set ^GITConfig("error")="c:\git.error.txt"            // temp. file to store git error
```

* Configure your namespace to use *Studio.SourceControl.GIT* as the source control class:
  * Management Portal > System Administration > Additional Settings > Source Control
  * Select your namespace
  * Select *Studio.SourceControl.GIT* as the source control class
