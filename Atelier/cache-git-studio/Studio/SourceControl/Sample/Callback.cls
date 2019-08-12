/// Updated at 08/12/2019 14:34:01
Class Studio.SourceControl.Sample.Callback Extends %RegisteredObject
{

ClassMethod Change(updated As %List, deleted As %List) As %Status
{
	write !,"updated:"
	zwrite updated
	write !,"deleted:"
	zwrite deleted
	
	quit $$$OK
}

}
