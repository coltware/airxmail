package com.coltware.airxmail.pop3
{
	import com.coltware.airxmail.MimeMessage;
	
	import flash.utils.ByteArray;
	
	public class POP3MessageEvent extends POP3Event
	{
		public static const POP3_MESSAGE:String = "pop3Message";
		
		public var octets:int = 0;
		public var source:ByteArray;
		
		public function POP3MessageEvent(type:String)
		{
			super(type);
		}
		
		public function getMimeMessage():MimeMessage{
			var msg:MimeMessage = result as MimeMessage;
			return msg;
		}
		
	}
}