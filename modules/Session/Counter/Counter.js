/*
 * FUNCTIONS THAT PERFORM THE COMMON AJAX TASKS IN WSRF::Lite.
 */

/**
 * newXMLHttpRequest() returns an XMLHttpRequest object or a similar entity 
 * that is capable of achieving the same functionality, depending on
 * the Web browser.
 */
function newXMLHttpRequest()
{
    var req = null;
    
	if (window.XMLHttpRequest)
	{
		req = new XMLHttpRequest();
		if (req.overrideMimeType) 
		{
			req.overrideMimeType('text/xml');
		}
	}
	else if (window.ActiveXObject) 
	{
		try 
		{
		   req = new ActiveXObject("Msxml2.XMLHTTP");
		} 
 		catch (e)
		{
			try 
			{
				req = new ActiveXObject("Microsoft.XMLHTTP");
			} 
 			catch (e) {
 				alert("Sorry, it seems that your browser does not support XMLHttpRequest.");
 			}
		}
	}
	
	return req;
}

/*
 * Declaration of the WSRF namespaces.
 */
var wsrpNS = "http://docs.oasis-open.org/wsrf/rp-2";
var wsrlNS = "http://docs.oasis-open.org/wsrf/rl-2";

/**
 * updateResourceProperties(xmlContent) is a generic function for setting
 * the WS-Resource properties using the HTTP PUT binding of WSRF::Lite.
 * It is not specific to a particular type of WS-Resource.
 * Argument xmlContent may contain several XML elements in a string, as
 * they would be contained within the <wsrp:ResourceProperties /> element.
 *
 * This function calls updatePageFromResourcePropertiesDocument(respDocElem)
 * upon success and updatePageAfterError(msg) upon failure.
 */
function updateResourceProperties(xmlContent)
{
	var req = newXMLHttpRequest();
	indicateActive();

	req.onreadystatechange = function()
	{ 
		if(req.readyState == 4)
		{
			if(req.status == 200)
			{
				var respDocElem = req.responseXML.documentElement;
				updatePageFromResourcePropertiesDocument(respDocElem);
			}	
			else	
			{
				updatePageAfterError("Error: returned status code " + req.status + " " + req.statusText);
			}
			indicateIdle();
		} 
	}; 
	
 	var newValues = "<?xml version='1.0' encoding='ISO-8859-1'?>\n"
 		+ '<wsrp:ResourceProperties xmlns:wsrp="'+wsrpNS+'">'
 		+ xmlContent
 		+ '</wsrp:ResourceProperties>';

	req.open("PUT", window.location.href, true); 
	req.setRequestHeader("Content-Type", "text/xml"); 
	req.send(newValues); 

	return false;
}

/**
 * reloadResourcePropertiesDocument() is a generic function for getting
 * the WS-Resource properties using the HTTP GET binding of WSRF::Lite.
 * It is not specific to a particular type of WS-Resource.
 *
 * This function calls updatePageFromResourcePropertiesDocument(respDocElem)
 * upon success and updatePageAfterError(msg) upon failure.
 *
 * respDocElement is the document element of the ResourcePropertiesDocument.
 */
function reloadResourcePropertiesDocument()
{ 
	var req = newXMLHttpRequest();
	indicateActive();

	req.onreadystatechange = function()
	{ 
		if(req.readyState == 4)
		{
			if(req.status == 200)
			{
				var respDocElem = req.responseXML.documentElement;
				updatePageFromResourcePropertiesDocument(respDocElem);
			}	
			else	
			{
				updatePageAfterError("Error: returned status code " + req.status + " " + req.statusText);
			}
			indicateIdle();
		} 
	}; 
	
	req.open("GET", window.location.href, true); 
	req.setRequestHeader("Content-Type", "application/xml"); 
	req.send(null); 
}





/*
 * FUNCTIONS RELATED TO THE AUTOMATIC POLLING.
 *
 * The following functions and variables are used for performing updates
 * of the page at regular intervals. They are called by buttons on the
 * page.
 * The function that is associated with the timer is
 * "reloadResourcePropertiesDocument()", which is defined as part of the
 * common functions below.
 */

var rate = 10;
var timerID = setInterval("reloadResourcePropertiesDocument()", rate * 1000);

function stopUpdating()
{
	clearInterval(timerID);
	return false;
}

function resumeUpdating()
{
	timerID = setInterval("reloadResourcePropertiesDocument()", rate * 1000);
	return false;
}

function increaseUpdateRate()
{
	var diff = 0;
	
	if ( rate > 100 )
	{
		diff = 50;
	} 
	else if ( rate > 50 )
	{
		diff = 20;  
	}
	else if ( rate > 20 )
	{
		diff = 10;
	} 
	else if ( rate > 3 )
	{
		diff = 1;
	} 
	
	rate = rate - diff;
	clearInterval(timerID);
	timerID = setInterval("reloadResourcePropertiesDocument()", rate * 1000);
	document.getElementById("updateRate").firstChild.data = rate;
	return false;
}

function decreaseUpdateRate()
{
	var diff = 50;
	
	if ( rate  < 20 )
	{
		diff = 1;
	} 
	else if ( rate < 50 )
	{
		diff = 10;  
	}
	else if ( rate < 100 )
	{
		diff = 20;
	} 
	
	rate = rate + diff;
	clearInterval(timerID);
	timerID = setInterval("reloadResourcePropertiesDocument()", rate * 1000);
	document.getElementById("updateRate").firstChild.data = rate;
	return false;
}





/*
 * FUNCTIONS THAT ARE SPECIFIC TO THE COUNTER EXAMPLE.
 */

/*
 * Declaration of the Counter properties namespace.
 */
var mmkNS = "http://www.sve.man.ac.uk/Counter";

/**
 * indicateActive() changes the appearance of the page to reflect
 * to the user that a request is being performed in the background (to active).
 */
function indicateActive()
{
	document.getElementById("submitUpdates").getAttributeNode('class').value = 'active';
}

/**
 * indicateIdle() changes the appearance of the page to reflect
 * to the user that a background request has completed.
 */
function indicateIdle()
{
	document.getElementById("submitUpdates").getAttributeNode('class').value = 'idle';
}

/**
 * onLoad() is called when the page is loaded (just after the XSL 
 * transformation from XML ResourcePropertiesDocument to XHTML.
 * This function initialises the local time and the update rate
 * on the webpage.
 */
function onLoad()
{
	var localTimeElement = document.getElementById("localtime");
	if (!localTimeElement.firstChild) {
		var textNode = document.createTextNode((new Date).toLocaleString());
		localTimeElement.appendChild(textNode);
	} else {
		localTimeElement.firstChild.data = (new Date).toLocaleString();
	}
	
	document.getElementById("updateRate").firstChild.data = rate;
}

/**
 * updatePageFromResourcePropertiesDocument(respDocElem) is called by the
 * generic updateResourceProperties(xmlContent) and 
 * reloadResourcePropertiesDocument() when the ResoucePropertiesDocument 
 * has succesfully been retrieved.
 * It is where mapping a piece of information in the ResourceProperty to
 * an HTML element is done.
 */
function updatePageFromResourcePropertiesDocument(respDocElem)
{
	try {				
		document.getElementById("localtime").firstChild.data = (new Date).toLocaleString();
		
		/*
		 * This tests whether-or-not getElementsByTagNameNS is supported.
		 * getElementsByTagNameNS differs from getElementsByTagName in that 
		 * it uses the namespace, which is required here because several 
		 * namespaces are used.
		 * When this function is not supported, selectNodes (with namespace 
		 * declaration) is used.
		 *
		 * Firefox supports getElementsByTagNameNS but not selectNodes.
		 * Internet Explorer supports selectNodes but not getElementsByTagNameNS.
		 */
		if (respDocElem.getElementsByTagNameNS) {
			// Probably Firefox
			document.getElementById('count').value = respDocElem.getElementsByTagNameNS(mmkNS,'count')[0].firstChild.data;
			var terminationTimeElement = respDocElem.getElementsByTagNameNS(wsrlNS,'TerminationTime')[0].firstChild;
			document.getElementById('TerminationTime').value = terminationTimeElement ? terminationTimeElement.data : 'Never';	
			document.getElementById("CurrentTime").firstChild.data  = respDocElem.getElementsByTagNameNS(wsrlNS,'CurrentTime')[0].firstChild.data;	
		} else {
			// Probably Internet Explorer
			respDocElem.ownerDocument.setProperty("SelectionNamespaces",
				 "xmlns:mmk='"+mmkNS+"' "
				+"xmlns:wsrl='"+wsrlNS+"' ");
			document.getElementById('count').getAttributeNode('value').value = respDocElem.selectNodes('mmk:count')[0].firstChild.data;
			var terminationTimeElement = respDocElem.getElementsByTagName('wsrl:TerminationTime')[0].firstChild;
			document.getElementById('TerminationTime').getAttributeNode('value').value = terminationTimeElement ? terminationTimeElement.data : 'Never';
			document.getElementById("CurrentTime").firstChild.data  = respDocElem.getElementsByTagName('wsrl:CurrentTime')[0].firstChild.data;
		}
	} catch (e) {
	}
}

/**
 * updatePageFromResourcePropertiesDocument(respDocElem) is called by the
 * generic updateResourceProperties(xmlContent) and 
 * reloadResourcePropertiesDocument() functions.
 * This handles what to do when an error has occurred during a asynchronous request.
 */
function updatePageAfterError(errorMsg)
{
	document.getElementById("count").getAttributeNode('value').value = errorMsg;
}

/**
 * updateResourcePropertiesFromPage() takes the relevant pieces of information from
 * the browser (typically from an HTML form) and convert them as a succession of
 *  XML elements to be passed to updateResourceProperties(xmlContent), as defined above.
 */
function updateResourcePropertiesFromPage()
{
 	var xmlContent =
 		'<mmk:count xmlns:mmk="'+mmkNS+'">' + document.getElementById('count').value + '</mmk:count>'
 	  + '<wsrl:TerminationTime xmlns:wsrl="'+wsrlNS+'">' + document.getElementById('TerminationTime').value + '</wsrl:TerminationTime>';
 	updateResourceProperties(xmlContent);
}


