/// Sample callback class
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
