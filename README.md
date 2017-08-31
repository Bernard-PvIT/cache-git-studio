# Git Plugin for Studio

[InterSystems Caché](http://www.intersystems.com/our-products/cache/cache-overview/) Studio plugin to use Git.

## Requirements
* Git SCM

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

* Load and compile the downloaded source code 
```
set path="C:\Temp\cache-iat-pubsub\cache"
do $system.OBJ.ImportDir(path,"*.xml","ck",.error,1)
```

* Configure *cache-git-studio* using **^GITConfig** global:

**Windows** configuration example:
```
// path to git binaries
set ^GITConfig($username,"gitpath")="C:\Users\MyUser\AppData\Local\Programs\Git\bin\"	

// path to git work directory
set ^GITConfig($username,"workdir")="c:\sandbox\MyApp\"         	                         

// [optional] author name used in git commits
set ^GITConfig($username,"authorname")="John Doe"            	  	                         

// [optional] author email used in git commits
set ^GITConfig($username,"authoremail")="johndoe@server.com"    	                       

// temp. file to store git output
set ^GITConfig($username,"output")="c:\git.output.txt"

// temp. file to store git errors
set ^GITConfig($username,"error")="c:\git.error.txt"

// [optional] use UDL format instead of XML (default)
set ^GITConfig($username,"udl")="1" 

// [optional] use xml as file extension always.
// when using UDL you may want to turn this off (0) so extensions will be like: cls, mac, etc.
set ^GITConfig($username,"xmlextension")="0"

// [optional] classmethod to call after reloading files
set ^GITConfig($username,"on.reloadfiles")=$lb("Studio.SourceControl.Sample.Callback", "Change")

// [optional] classmethod to call after a workdir load operation
set ^GITConfig($username,"on.workdirload")=$lb("Studio.SourceControl.Sample.Callback", "Change")

// [optional] classmethod to call after a pull operation
set ^GITConfig($username,"on.pull")=$lb("Studio.SourceControl.Sample.Callback", "Change")
```

**Linux** configuration example:
```
// path to git binaries
set ^GITConfig($username,"gitpath")="/usr/local/git/bin/"  	

// path to git work directory
set ^GITConfig($username,"workdir")="/workspace/myuser/myrepo/"

// path to home directory
set ^GITConfig($username,"homedir")="/home/ensemble"            	

// [optional] author name used in git commits
set ^GITConfig($username,"authorname")="John Doe"            	  	                         

// [optional] author email used in git commits
set ^GITConfig($username,"authoremail")="johndoe@server.com"    	                       

// temp. file to store git output
set ^GITConfig($username,"output")="/tmp/output.txt"

// temp. file to store git errors
set ^GITConfig($username,"error")="/tmp/error.txt"

// [optional] use UDL format instead of XML (default)
set ^GITConfig($username,"udl")="1" 

// [optional] use xml as file extension always. 
// when using UDL you may want to turn this off (0) so extensions will be like: cls, mac, etc.
set ^GITConfig($username,"xmlextension")="0"

// [optional] classmethod to call after reloading files
set ^GITConfig($username,"on.reloadfiles")=$lb("Studio.SourceControl.Sample.Callback", "Change")

// [optional] classmethod to call after a workdir load operation
set ^GITConfig($username,"on.workdirload")=$lb("Studio.SourceControl.Sample.Callback", "Change")

// [optional] classmethod to call after a pull operation
set ^GITConfig($username,"on.pull")=$lb("Studio.SourceControl.Sample.Callback", "Change")
```

* Configure your namespace to use *Studio.SourceControl.GIT* as the source control class:
  * Management Portal > System Administration > Additional Settings > Source Control
  * Select your namespace
  * Select *Studio.SourceControl.GIT* as the source control class
