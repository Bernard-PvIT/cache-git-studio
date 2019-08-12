/// Updated at 08/12/2019 14:33:14
Class Studio.SourceControl.GIT Extends %Studio.SourceControl.Base
{

Parameter VERSION = 0.5;

/// First menu item that appears
Parameter FIRSTMENUITEM = "Add";

/// Not supported item types (or that you don't want to be exported/imported to/from git)
Parameter NOTSUPPORTEDTYPES = "PRJ,PKG";

/// Extensions that can not be exported as UDL. XML will always be used.
Parameter NOTUDLEXTENSIONS = {$lb("hl7","dfi","lut")};

/// Logger instance to display messages
Property Logger As Studio.SourceControl.Util.Logger [ Private ];

/// GIT client wrapper
Property Command As Studio.SourceControl.Command.GITClient [ Private ];

Property IsControlled As %Boolean [ Private ];

Property IsCheckedOut As %Boolean [ Private ];

Property IsEditable As %Boolean [ Private ];

Property IsAdded As %Boolean [ Private ];

Property OnReloadFiles As %List [ Private ];

Property OnWorkDirLoad As %List [ Private ];

Property OnPull As %List [ Private ];

/// Export files in UDL format
Property UseUDL As %Boolean [ Private ];

/// Use always XML as filename extension 
Property UseXMLExtension As %Boolean [ Private ];

/// Studio menu options
XData Menu
{
<MenuBase>
<Menu Name="Git" Type="0">
<MenuItem Name="Add" Save="100"/>
<MenuItem Name="Unstage"/>
<MenuItem Name="Revert changes" Save="100"/>
<MenuItem Name="Log"/>
<MenuItem Name="Diff"/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Status"/>
<MenuItem Name="Add All Changes"/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Commit..."/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Switch to Branch..."/>
<MenuItem Name="Create and Switch to Branch..."/>
<MenuItem Name="Diff with Branch..."/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Merge with..."/>
<MenuItem Name="Abort merge"/>
<MenuItem Name="Load status changes"/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Diff with origin"/>
<MenuItem Name="Pull origin->local"/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Push local->origin"/>
<MenuItem Separator="1" Name="--------------"/>
<MenuItem Name="Workdir - Load files"/>
</Menu>
</MenuBase>
}

/// 
/// Callback called on each menu item. Allows to enable/disable items
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	set ret=$$$OK
	try {
		set menu=$piece(MenuName,","),name=$piece(MenuName,",",2)
		if menu'="Git" quit
		
		// no file is selected
		if ((InternalName="") && ((name="Add")||(name="Unstage")) ) {
			set Enabled=0
			quit
		}
	
		// get file source control status only once for all MenuItems
		if name=..#FIRSTMENUITEM {
			$$$THROWONERROR(sc, ..GetStatus(InternalName,.iscontrolled,.iseditable,.ischeckedout,.isadded))
			set ..IsControlled = iscontrolled
			set ..IsEditable = iseditable
			set ..IsCheckedOut = ischeckedout
			set ..IsAdded = isadded
		} 
	
		/*
		simplify git menu options. all options enabled.
		
		// disable menu items depending on file status
		if name="Add" {
			set:((..IsControlled)) Enabled=0
		} elseif (name="Unstage") {
			set:(('..IsControlled)||(..IsCheckedOut)||('..IsAdded)) Enabled=0
		} elseif (name="Revert changes") {
			set:(('..IsControlled)||('..IsCheckedOut)) Enabled=0
		} elseif (name="Log")||(name="Diff") {
			set:(('..IsControlled)) Enabled=0
		}
		*/
		
		// display current branch name
		if name="Status" {
			set DisplayName = "Status ["_..Command.GetCurrentBranch()_"]"
		}
	} catch errObj {
		set ret = errObj.AsStatus()
	}
	quit ret
}

/// 
/// Handles user selected action from menu
Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	set Action=0,Target="",Msg="",Reload=0
	
	set menu=$piece(Name,",")
	if menu'="Git" quit $$$OK
	
	set name=$piece(Name,",",2)
	if menu="Git" {
		if ((name="Revert changes")||(name="Unstage")) {
			set Action=1
			set Target="File """_InternalName_""". Are you sure you want to """_name_"""?"
		}
		elseif (name="Workdir - Load files")||(name="Abort merge") {
			set Action=1
			set Target="WARNING: Are you sure you want to """_name_"""?"
		}
		elseif (name="Commit...")||(name="Amend commit...") {
			set Action=7
			set Target="WARNING: Committing ALL changes. Enter Check-in message here"
		}
		elseif ((name="Create and Switch to Branch...")||(name="Switch to Branch...")||(name="Diff with Branch...")||(name="Merge with...")) {
			set Action=7
			set Target=$piece(name,"...")_". Enter branch name:"
		}
		else {
			quit ..AfterUserAction(Type,Name,InternalName,1,,.Reload)
		}
	}
	quit $$$OK
}

/// 
/// Perfoms the selected action itself
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	set Reload=0
	
	set menu=$piece(Name,",")
	if menu'="Git" quit $$$OK
	
	set name=$piece(Name,",",2)
	set issupported=..IsSupported(InternalName)
	if $$$ISERR(issupported) quit issupported
	
	if Answer'=1 quit $$$OK
	
	if ((name="Add")||(name="Stage")) quit ..Add(InternalName,Msg)
	if name="Unstage" quit ..Unstage(InternalName)
	if name="Revert changes" quit ..Revert(InternalName)
	if name="Log" quit ..Log(InternalName)
	if name="Diff" quit ..Diff(InternalName)
	
	if name="Status" quit ..Status(InternalName)
	if name="Add All Changes" quit ..AddAllChanges()
	if name="Commit..." quit ..Commit(InternalName,Msg)
	if name="Amend commit..." quit ..Commit(InternalName,Msg,1)
	
	if name="Switch to Branch..." quit ..SwitchToBranch(Msg)
	if name="Create and Switch to Branch..." quit ..CreateAndSwitchToBranch(Msg)
	if name="Diff with Branch..." quit ..DiffWithBranch(Msg)
	
	if name="List Branches" quit ..ListBranches(Msg)
	
	if name="Merge with..." quit ..Merge(Msg)
	if name="Abort merge" quit ..AbortMerge()
	if name="Load status changes" quit ..LoadStatusChanges()
	
	if name="Diff with origin" quit ..Pull(1)
	if name="Pull origin->local" quit ..Pull()
	if name="Push local->origin" quit ..Push()
	
	if name="Workdir - Load files" quit ..WorkdirLoadFiles(..Command.WorkDir)
	
	quit $$$OK
}

/// 
/// Initialization. Load configuration and show status of work dir.
Method Login(Name As %String, Password As %String) As %Status
{
	#define GetConfig(%name,%default) $get(^GITConfig($username,%name), %default)
	
	set ret=$$$OK
	
	try {
		set ..Logger = ##class(Studio.SourceControl.Util.Logger).%New()
		do ..Logger.Info("=========================================================")
    	do ..Logger.Info(">GIT Source Control")
    	
    	set gitpath = $$$GetConfig("gitpath", "")
		set workdir = $$$GetConfig("workdir","")
		set homedir = $$$GetConfig("homedir","")
		set authorname = $$$GetConfig("authorname","")
		set authoremail = $$$GetConfig("authoremail","")
		set output = $$$GetConfig("output","")
		set error = $$$GetConfig("error","")
		set ..OnWorkDirLoad = $$$GetConfig("on.workdirload","")
		set ..OnPull = $$$GetConfig("on.pull","")
		set ..OnReloadFiles = $$$GetConfig("on.reloadfiles","")
		set ..UseUDL = $$$GetConfig("udl",0)
		set ..UseXMLExtension = $$$GetConfig("xmlextension",1)
	
    	set ..Command = ##class(Studio.SourceControl.Command.GITClient).%New(gitpath, workdir, homedir, authorname, authoremail, output, error)
    	do ..Logger.Info(">Working Directory: "_..Command.WorkDir)
	
		$$$THROWONERROR(sc,..Status(""))		
	} catch errObj {
		set sc = errObj.AsStatus()
		do DecomposeStatus^%apiOBJ(sc,.err,"d")
 		for i=1:1:err do ..Logger.Error(err(i))
		
		set tError="Error while checking git status. GIT Source Control IS NOT initialized. Check your ^GITConfig global"
	    set ret=$$$ERROR($$$GeneralError,tError)
	    do ..Logger.Error(tError)
	}
	do ..Logger.Info("========================================================="_$char(13))
	
	quit ret
}

/// 
/// OnBeforeLoad. Loads source controlled files from external file
Method OnBeforeLoad(InternalName As %String) As %Status
{
 set InternalName = ..NormalizeInternalName(InternalName)
 set extname = ..ExternalName(InternalName)
 quit:extname="" $$$OK
 
 // skip the import if not in source control
 if '..IsInSourceControl(InternalName) {
	 do ..Logger.Info(InternalName_" is not in source control, skipping import") 
	 quit $$$OK
 }
 
 // if the timestamp on the file is the same as the last time it was imported 
 // then there is nothing to do as it is already up to date
 if ##class(%File).GetFileDateModified(extname) = $get(^SourceControl(0,InternalName)) quit $$$OK

 // call the function to do the import
 set sc=$system.OBJ.Load(extname,"-l-d")
 if $$$ISOK(sc) {
 	do ..Logger.Info("Imported '"_InternalName_"' from file '"_extname_"'")
 	set ^SourceControl(0,InternalName)=##class(%File).GetFileDateModified(extname)
 	set ^SourceControl(1,InternalName)=##class(%RoutineMgr).TS(InternalName)
 } else {
 	Do DecomposeStatus^%apiOBJ(sc,.err,"d")
 	for i=1:1:err do ..Logger.Error(err(i))
 }
 quit sc
}

/// 
/// OnAfterSave. Exports source controlled files to external file
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject) As %Status
{
	set filename=..ExternalName(InternalName)
 	if filename="" Quit $$$OK

 	// if the timestamp of the item in Cache has not changed then there is no point in saving it again
 	if ##class(%RoutineMgr).TS(InternalName)=$get(^SourceControl(1,InternalName)) Quit $$$OK

 	// call the export function
 	if (..IsInSourceControl(InternalName)) {
 		set sc = ..ExportToFile(InternalName, filename)
 		if $$$ISOK(sc) {
 			do ..Logger.Info("Exported '"_InternalName_"' to file '"_filename_"'")
 			set ^SourceControl(0,InternalName)=##class(%File).GetFileDateModified(filename)
 			set ^SourceControl(1,InternalName)=##class(%RoutineMgr).TS(InternalName)
 		} else {
 			do DecomposeStatus^%apiOBJ(sc,.err,"d")
 			for i=1:1:err do ..Logger.Error(err(i))
 		}
 	}
 	quit $$$OK
}

/// 
/// Exports to external file
Method ExportToFile(InternalName As %String, Filename As %String) As %Status
{
	#define isUDLSupported ($system.Version.GetNumber()>=2016.2)
	
	#if $$$isUDLSupported
		// Caché version supports exporting as UDL
		// UDL option enabled and file extension supports UDL, export as UDL
		set ext = $zconvert($piece(InternalName,".",$length(InternalName,".")),"l")
		if ..UseUDL,..CanExportExtensionUDL(ext) {
			quit $system.OBJ.ExportUDL(InternalName, Filename, "-d /diffexport")
		}
	#else
		// Caché does not support exporting as UDL.
		// UDL option enabled, log an error and continue to export as XML.
		if ..UseUDL {
			do ..Logger.Error("Caché version "_$zv_" does not support exporting as UDL. Using XML instead...")
		}
	#endif
	
	// Default, export as XML.
	quit $system.OBJ.Export(InternalName, Filename, "-d /diffexport")
}

/// 
/// OnAfterCompile. Same as OnAfterSave
Method OnAfterCompile(InternalName As %String) As %Status
{
 	quit ..OnAfterSave(InternalName)
}

/// 
/// Called after an item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
	if ..IsInSourceControl(InternalName) {
		quit ..DeleteControlledItem(InternalName)
	}
	quit $$$OK
}

/// 
/// Deletes a source controlled item
Method DeleteControlledItem(InternalName As %String) As %Status
{
	set extname = ..ExternalName(InternalName)
	do ..Logger.Info("Deleting file: "_extname)
	set ret = ##class(%File).Delete(extname)
		
	kill ^SourceControl(0,InternalName)
	kill ^SourceControl(1,InternalName)
	
	quit ret
}

/// 
/// Provides a normalized way to format InternalNames (uppercase extension)
ClassMethod NormalizeInternalName(InternalName As %String)
{
	set name=$piece(InternalName,".",1,$length(InternalName,".")-1)
 	set ext=$zconvert($piece(InternalName,".",$length(InternalName,".")),"U")
 	quit name_"."_ext
}

/// 
/// Returns the external name (external file name) corresponding to a Caché element
Method ExternalName(InternalName As %String) As %String
{
	// check if it is a UserType (e.g. BPL, DTL, etc.)
	if ##class(%RoutineMgr).UserType(InternalName,.docclass,.doctype) {
		// check for a real abstract document subclass (or GetOther() may not work)
		if $classmethod(docclass,"%IsA","%Studio.AbstractDocument") {
			set actualName = $classmethod(docclass,"GetOther",InternalName)
			// the actualName is only valid if we get a single .cls as a result
			if actualName'[",",$zconvert($piece(actualName,".",$length(actualName,".")),"U")="CLS" {
				// we use what GetOther() gives us, thus Demo.Loan.FindRateProcess.bpl becomes Demo.Loan.FindRateProcess.cls
				set InternalName = actualName
			}
		}
	}
	
 	set name=$piece(InternalName,".",1,$length(InternalName,".")-1)
 	set ext=$zconvert($piece(InternalName,".",$length(InternalName,".")),"l")
 	quit:name="" ""
 	
 	set filename=ext_"/"_$translate(name,".","/")_$case(..UseXMLExtension, 1:".xml", :"."_ext)
 	quit ..Command.CacheDir_filename
}

/// 
/// Returns the internal name corresponding to an external file
Method InternalName(ExternalName As %String) As %String
{
 	// ignore files which are not under cache subdir
 	if ExternalName'[..Command.#CACHEDIRNAME quit ""
 	
 	// remove cache subdir name to calculate InternalName
 	set ExternalName = $replace(ExternalName,..Command.#CACHEDIRNAME,"")
 	
 	set ext=$zconvert($piece(ExternalName,"/"),"U")
 	set left=$piece(ExternalName,"/",2,$length(ExternalName,"/"))
 	set name=$piece(left,".")
 	set result=$translate(name,"/",".")_"."_ext
 	quit result
}

/// 
/// Prints out output from git command
Method Print(ByRef pOutput) As %String
{
	try {
		set next=""
		for {
			set next=$order(pOutput(next))
			quit:next=""
       		do ..Logger.Info(pOutput(next))
   		}
	} catch (errObj) {
		// nothing
	}
	quit $$$OK
}

/// 
/// Returns if an item is supported or not
Method IsSupported(InternalName As %String) As %Status [ Private ]
{
	set ret=$$$OK
	
	set ntypes=$length(..#NOTSUPPORTEDTYPES,",")
	for i=1:1:ntypes {
		set type=$piece(..#NOTSUPPORTEDTYPES,",",i)
		if $zcvt(InternalName,"U")[type {
			set tError="Error: "_type_" items are not currently supported"
	    	set ret=$$$ERROR($$$GeneralError,tError)
	    	do ..Logger.Error(tError)
			quit
		}
	}
	
	quit ret
}

/// 
/// Returns if an extension can 
Method CanExportExtensionUDL(extension As %String = "") As %Integer
{
	quit ($listfind(..#NOTUDLEXTENSIONS, extension)=0)
}

/// 
/// Reloads files passed <files> list:
/// Files marked as "D" will be deleted, rest will be reloaded
/// Each file entry should be like:
/// A path/file.xml
/// M path/file1.xml
/// D path/file2.xml
Method ReloadFiles(ByRef files, Output updated, Output deleted) [ Private ]
{
	set next="", updated="", deleted=""
	for {
		set next=$order(files(next))
		quit:next=""
		
		set line=files(next)
		set line=$tr(line,$c(9)," ")
		set line=$zstrip(line,"=W")
		
		set status=$p(line," ",1)
		set file=$p(line," ",2)
		
		set internalname=..InternalName(file)
		if internalname="" {
			do ..Logger.Info(">>Ignoring "_file)
		}
		elseif status'="D" {
			do ..Logger.Info(">>Loading "_internalname)
			set tSC=..OnBeforeLoad(internalname)
			set updated = updated_$lb(internalname)
		}
		elseif status="D" {
			do ..Logger.Info(">>Deleting "_internalname)
			set tSC=##class(%RoutineMgr).Delete(internalname)
			set tSC=..DeleteControlledItem(internalname)
			set deleted = deleted_$lb(internalname)
		}
	}
	
	// callback
	if ..OnReloadFiles'=""{
		do ..Logger.Info($char(13)_">Calling on.reloadfiles callback: "_$listget(..OnReloadFiles,1)_":"_$listget(..OnReloadFiles,2))
		do ..Logger.Info(">result="_$classmethod($listget(..OnReloadFiles,1), $listget(..OnReloadFiles,2), updated, deleted))
	}
}

// ======================

// SOURCE CONTROL CALLS

// ======================

/// 
/// Returns status of an item 
Method GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef IsAdded As %String) As %Status
{
 	quit:InternalName="" $$$OK
 	
 	set (statuscode,statusdesc)=""
 	set Editable=0,IsCheckedOut=0,UserCheckedOut=""
 	set extname=..ExternalName(InternalName)
 
 	set exists=##class(%File).Exists(extname)
 	if exists {
 		set tSC = ..Command.Status(extname, .statuscode, .statusdesc, .output, 0)
 		if $$$ISERR(tSC) quit tSC
 	}
 	set IsInSourceControl=((exists)&&(statuscode'="?")&&(statuscode'=""))
 	set Editable=1
 	set IsCheckedOut=(statuscode="M")
 	set IsAdded=(statuscode="A")
 	quit $$$OK
}

/// 
/// Commits
Method Commit(InternalName As %String, Description As %String, pAmend As %Boolean = 0) As %Status
{
 	// export the latest version
 	set tSC=..OnAfterSave(InternalName)
 	if $$$ISERR(tSC) quit tSC

 	// git commit
 	set tSC=..Command.Commit(..ExternalName(InternalName), Description, .output, pAmend, 1)
 	do ..Print(.output)
 	quit tSC
}

/// 
/// Reverts an item
Method Revert(InternalName As %String) As %Status
{
	set tSC=..Command.Checkout(..ExternalName(InternalName),.output)
	do ..Print(.output)
	if $$$ISERR(tSC) quit tSC
	
	quit ..OnBeforeLoad(InternalName)
}

/// 
/// Check if item is under source control
Method IsInSourceControl(InternalName As %String) As %Boolean
{
	set tSC = ..GetStatus(InternalName, .isinsourcecontrol, .iseditable, .ischeckedout, .isadded)
 	quit $get(isinsourcecontrol,0)
}

/// 
/// Adds an item
Method Add(InternalName As %String, Description As %String) As %Status
{
	// export the class
	set extname=..ExternalName(InternalName)
	set sc = ..ExportToFile(InternalName, extname)
	
	set tSC=..Command.Add(extname,.output)
	do ..Print(.output)
	if $$$ISERR(tSC) quit tSC
	
	quit ..OnBeforeLoad(InternalName)
}

/// 
/// Returns source control log of an item
Method Log(InternalName As %String) As %Status
{
	set tSC=..Command.Log(..ExternalName(InternalName),.output)
	do ..Print(.output)
	quit tSC
}

/// 
/// Returns source control log of an item
Method Diff(InternalName As %String) As %Status
{
	set tSC=..Command.Diff(..ExternalName(InternalName),.output)
	do ..Print(.output)
	quit tSC
}

/// 
/// Returns source control status of entire working directory
Method Status(InternalName As %String) As %Status
{
	set tSC=..Command.Status("",.statuscode,.statusdesc,.output)
	do ..Print(.output)
	quit tSC
}

/// 
/// Adds all changes to stage
Method AddAllChanges() As %Status
{
	set tSC=..Command.Add("",.output)
	do ..Print(.output)
	if $$$ISERR(tSC) quit tSC
	
	set tSC = ..Status("")
	quit tSC
}

/// 
/// Unstages a file
Method Unstage(InternalName As %String) As %Status
{
	set tSC=..Command.Reset(..ExternalName(InternalName),.output,1)
	do ..Print(.output)
	quit tSC
}

/// 
/// Creates a new branch
Method NewBranch(pBranch As %String) As %Status
{
	set tSC=..Command.Branch(pBranch,.output)
	do ..Print(.output)
	quit tSC
}

/// 
/// List branches
Method ListBranches(pBranch As %String) As %Status
{
	set tSC=..Command.Branch("",.output)
	do ..Print(.output)
	quit tSC
}

/// 
/// Creates a branch and then switch to it
Method CreateAndSwitchToBranch(pBranch As %String) As %Status
{
	
	set tSC = ..NewBranch(pBranch)
	if $$$ISERR(tSC) quit tSC
	
	quit ..SwitchToBranch(pBranch)
}

/// 
/// Switchs workspace to branch
Method SwitchToBranch(pBranch As %String) As %Status
{
	// diff with new branch
	set tSC=..Command.DiffStatus(pBranch, 1, .files,0)
	if $$$ISERR(tSC) quit tSC
	
	// switch branch
	set current=..Command.GetCurrentBranch()
	set tSC=..Command.Checkout("",pBranch,.output,1)
	do ..Print(.output)
	if $$$ISERR(tSC) quit tSC
	
	// reload files
	do ..Logger.Info($c(13)_">Analyzing files after changing from """_current_""" to """_pBranch_"""")
	do ..ReloadFiles(.files, .updated, .deleted)
	do ..Logger.Info(">Completed.")
	
	quit tSC
}

/// 
/// Diffs current branch with other branch
Method DiffWithBranch(pBranch As %String) As %Status
{
	set tSC=..Command.DiffStat(pBranch, 0, .output)
	do ..Print(.output)
	quit tSC
}

/// 
/// Merges with a branch
Method Merge(pBranch As %String) As %Status
{
	set tSC=..Command.Merge(pBranch,0,.output,1)
	do ..Print(.output)
	quit tSC
}

/// 
/// Aborts a merge
Method AbortMerge() As %Status
{
	set tSC=..Command.Merge("",1,.output,1)
	do ..Print(.output)
	quit tSC
}

/// 
/// Lists current git config
Method ListConfig() As %Status
{
	set tSC=..Command.ListConfig(.output)
	do ..Print(.output)
	quit tSC
}

/// 
/// Loads changes (as shown in git status)
Method LoadStatusChanges() As %Status
{
	set tSC=..Command.Status("",.statuscode,.statusdesc,.output,0,1)
	do ..Print(.output)
	
	// reload / delete files
	do ..Logger.Info($c(13)_">Reloading changed files:")
	do ..ReloadFiles(.output, .updated, .deleted)
	do ..Logger.Info(">Completed.")
	
	quit tSC
}

/// 
/// Pushes local changes to origin
Method Push() As %Status
{
	set tSC=..Command.Push(.output,1)
	do ..Print(.output)
	quit tSC
}

/// 
/// Pulls fresh changes from origin to local
Method Pull(pDry As %Boolean = 0) As %Status
{
	// update remote origin info
	set tSC=..Command.RemoteUpdate("origin", .out1, 1)
	do ..Print(.out1)
	
	// get diff current..origin
	set current = ..Command.GetCurrentBranch()
	set tSC = ..Command.DiffStatus("origin"_"/"_current, 1, .out2, 1)
	do ..Print(.out2)
	
	if 'pDry {
		// pull
		set tSC=..Command.Pull(.out3, 1)
		do ..Print(.out3)
	
		// load changes into studio 
		do ..Logger.Info($c(13)_">Reloading diff with: origin"_"/"_current)
		do ..ReloadFiles(.out2, .updated, .deleted)
		do ..Logger.Info(">Completed.")
	}
	
	if $$$ISOK(tSC),..OnPull'=""{
		do ..Logger.Info($char(13)_">Calling on.pull callback: "_$listget(..OnPull,1)_":"_$listget(..OnPull,2))
		do ..Logger.Info(">result="_$classmethod($listget(..OnPull,1), $listget(..OnPull,2), updated, deleted))
	}
	
	quit tSC
}

/// 
/// Loads modified files from workdir and checks for troubled ^SourceControl entries
Method WorkdirLoadFiles(pPath As %String) As %Status
{
	set tSC=..Command.LsFiles(.output, 1)
	do ..Print(.output)
	
	// reload / delete files 
	do ..Logger.Info($c(13)_">Reloading files based on GIT status:")
	do ..ReloadFiles(.output, .updated, .deleted)
	do ..Logger.Info(">Completed.")
	
	// check for deleted
	set file=""
	for {
		set file=$order(^SourceControl(1,file))
		quit:file=""
		
		set extname=..ExternalName(file)
		if '##class(%File).Exists(extname) {
			do ..Logger.Info(">>Deleting "_file_" because it is in ^SourceControl but not in workdir")
			set tSC=##class(%RoutineMgr).Delete(file)
			set tSC=..DeleteControlledItem(file)
			kill ^SourceControl(1,file)
		}
	}
	
	// callback
	if $$$ISOK(tSC),..OnWorkDirLoad'=""{
		do ..Logger.Info($char(13)_">Calling on.workdirload callback: "_$listget(..OnWorkDirLoad,1)_":"_$listget(..OnWorkDirLoad,2))
		do ..Logger.Info(">result="_$classmethod($listget(..OnWorkDirLoad,1), $listget(..OnWorkDirLoad,2), updated, deleted))
	}
	
	quit tSC
}

/// 
/// Adds classes (only non-generated) which name starts with pStartsWith.
/// (useful to add a bunch of classes belonging to a package from Terminal).
ClassMethod AddClasses(pStartsWith As %String) As %Status
{
	set ret = $$$OK
	try {
		set control = ##class(Studio.SourceControl.GIT).%New($lb("", "", "0", "2015.200000"))
		
		set statement = ##class(%SQL.Statement).%New()
   		set sql = "select id from %Dictionary.ClassDefinition where id %startswith ? and generatedby is null"
   		do statement.%Prepare(sql)
   		set resultSet = statement.%Execute(pStartsWith)
   		
   		while resultSet.%Next() {
			set className = resultSet.ID_".cls"
			$$$ThrowOnError(control.Add(className))
   		}
   		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
