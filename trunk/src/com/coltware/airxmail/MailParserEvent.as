package com.coltware.airxmail
{
	import flash.events.Event;
	
	public class MailParserEvent extends Event
	{
		
		public static const MAIL_PARSER_ADD_CHILD:String = "mailParserAddChild";
		public static const MAIL_PARSER_HEADER_END:String = "mainParserHeaderEnd";
		
		public var item:Object;
		
		public function MailParserEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}