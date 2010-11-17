/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.imap
{
	import com.coltware.airxmail.MailEvent;
	
	public class IMAP4Event extends MailEvent
	{
		public static const IMAP4_CONNECT_OK:String = "imap4ConnectOk";
		public static const IMAP4_CONNECT_NG:String = "imap4ConnectNg";
		
		public static const IMAP4_COMMAND_BAD:String = "imap4CommandBad";
		public static const IMAP4_COMMAND_NO:String = "imap4CommandNo";
		
		public var client:IMAP4Client;
		protected var _result:Object;
		
		public function IMAP4Event(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function set result(obj:Object):void{
			_result = obj;
		}
	}
}