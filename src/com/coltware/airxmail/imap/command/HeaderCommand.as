/**
 *  Copyright (c)  2009-2011 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.imap.command
{
	import com.coltware.airxmail.imap.IMAP4MessageEvent;

	public class HeaderCommand extends MessageCommand
	{
		public function HeaderCommand(msgid:String, useUid:Boolean=true)
		{
			super(msgid, useUid,"(FLAGS RFC822.SIZE RFC822.HEADER)");
			this.kind = IMAP4MessageEvent.IMAP4_MESSAGE_KIND_HEADER;
		}
	}
}