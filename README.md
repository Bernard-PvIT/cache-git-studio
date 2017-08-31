# Git Plugin for Studio
[InterSystems Caché](http://www.intersystems.com/our-products/cache/cache-overview/) Studio plugin to use Git.

## Requirements
* [Git SCM](https://git-scm.com/downloads).

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

## Setup
Configure *cache-git-studio* using `^GITConfig` global.

### Windows example
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

### Linux example
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

Configure your namespace to use `Studio.SourceControl.GIT` as the source control class:
 * Management Portal > System Administration > Additional Settings > Source Control.
 * Select your namespace.
 * Select `Studio.SourceControl.GIT` as the source control class.

## Credentials management
* `cache-git-studio` does not prompt for passwords in Caché Studio.
* `cache-git-studio` does not provide any specific credentials management features. 
* If you need to perform password protected operations, it is needed that you configure your local installation to avoid git to prompt for any password.
* You must protect the files where your passwords are stored (file permissions).

### Windows
You can use the `_netrc` file of the effective O.S. user that run Caché processes to store your credentials.
Example: `C:\Users\user1\_netrc`
```
machine git.company.com
login user1 
password mypassword
```

### Linux
You can use [git-credential-store](https://git-scm.com/docs/git-credential-store).
```
git config credential.helper 'store --file=~/.git-credentials'
```

## Shared environment
Git is used generally in a non-shared environment, every developer has its own work environment.

However, in some cases you could need to use `cache-git-studio` in a shared environment (same instance, same namespace, different Caché developers).

In shared environments, a simple approach is:
* Use different Caché users for each developer.

* Use the same working directory for each developer, so source code will be exported/imported from the same shared location:
```
set ^GITConfig($username, "workdir")="/workspace/myproject/"
```

* Use different output and error temporary files for each developer:
```
set ^GITConfig($username,"output")="/tmp/git.output.jdoe"
set ^GITConfig($username,"output")="/tmp/git.error.jdoe"
```

* Use a common git user for all developers: All git actions will be performed using the same git user but commits will have different authors.

* Configure commit author for each developer:
```
^GITConfig($username,"authoremail")="john.doe@company.com"
^GITConfig($username,"authorname")="jdoe"
```
