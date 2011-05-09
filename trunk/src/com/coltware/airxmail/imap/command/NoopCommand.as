/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.imap.command
{
	import com.coltware.airxlib.utils.StringLineReader;
	import com.coltware.airxmail.imap.IMAP4Event;
	import com.coltware.airxmail_internal;
	
	use namespace airxmail_internal;
	
	public class NoopCommand extends IMAP4Command
	{
		public function NoopCommand()
		{
			super();
			this.key = "NOOP";
		}
		
		override protected function parseResult(reader:StringLineReader):void{
			var event:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_NOOP);
			event.$command = this;
			event.client = client;
			event.result = this.tag;
			client.dispatchEvent(event);
		}
	}
}