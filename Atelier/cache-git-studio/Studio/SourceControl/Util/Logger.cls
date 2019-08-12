/// 
/// Handles log messages using log levels
Class Studio.SourceControl.Util.Logger Extends %RegisteredObject
{

/// Current log level
Parameter LOGLEVEL = 2;

Parameter DEBUG = 1;

Parameter INFO = 2;

Parameter ERROR = 7;

ClassMethod Log(pLevel As %String, pMsg As %String, pNL As %Boolean = 1)
{
	if pLevel >= ..#LOGLEVEL {
		write:pNL !
		write pMsg
	}
	quit
}

ClassMethod Debug(pMsg As %String, pNL As %Boolean = 1)
{
	do ..Log(..#DEBUG, pMsg, pNL)
}

ClassMethod Error(pMsg As %String, pNL As %Boolean = 1)
{
	do ..Log(..#ERROR, pMsg, pNL)
}

ClassMethod Info(pMsg As %String, pNL As %Boolean = 1)
{
	do ..Log(..#INFO, pMsg, pNL)
}

}
