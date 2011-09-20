/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *  
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 * 
 */
package com.coltware.airxmail
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class TextStreamReaderEvent extends Event
	{
		public static const TEXT_STREAM_LINE:String = "textReaderLine";
		public var lineBytes:ByteArray;
		
		public function TextStreamReaderEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}