package com.coltware.airxmail.imap
{
	import com.coltware.airxlib.utils.StringLineReader;
	import com.coltware.airxmail.MailEvent;
	import com.coltware.airxmail_internal;
	
	public class IMAP4FetchEvent extends MailEvent
	{
		public static const IMAP4_FETCH_RESULT:String = "imap4FetchResult";
		
		private var _reader:StringLineReader;
		
		public function IMAP4FetchEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		airxmail_internal function set $reader(reader:StringLineReader):void{
			
			this._reader = reader;
		}
		
		public function getStringLineReader():StringLineReader{
			return this._reader;
		}
	}
}