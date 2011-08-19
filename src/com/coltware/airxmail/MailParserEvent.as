package com.coltware.airxmail
{
	import flash.events.Event;
	
	public class MailParserEvent extends Event
	{
		
		public static const MAIL_PARSER_ADD_CHILD:String = "mailParserAddChild";
		
		public var part:MimeBodyPart;
		
		public function MailParserEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}