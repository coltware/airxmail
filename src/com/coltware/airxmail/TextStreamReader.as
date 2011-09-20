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
	import com.coltware.airxmail_internal;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.text.TextRenderer;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.Timer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	use namespace airxmail_internal;
	
	/**
	 * 
	 *  TextSocketReaderの別名（Socketは関係がないので別なクラス名にする。)
	 * 
	 *  CR-LF(実装は面倒なのでLF)で必ず終わるレスポンスに対して行毎のレスポンスに変換してイベントを行うクラス
	 * 
	 *  IMAP4 はステータスが最後に来るのでレスポンスが頻繁にステータス行の途中で切れてしまう。
	 *  このために、ProgressEventからのレスポンスでは制御ができなくなってしまったのでこのクラスを使う。
	 * 
	 *  ※ ) 命令の結果が終了したら、clear()を実行する。
	 * 　    命令の結果が終了しているかどうかはプロトコル次第なので、自動ではできない。
	 * 
	 */
	public class TextStreamReader extends EventDispatcher
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.TextStreamReader");
		
		private static const CR:int 	= 0x0D;
		private static const LF:int 	= 0x0A;
		
		public var source:IDataInput;
		
		private var _result:ByteArray;
		private var _line:ByteArray;
		
		public function TextStreamReader(target:IEventDispatcher=null)
		{
			super(target);
			_result = new ByteArray();
			_line = new ByteArray();
		}
		
		public function get resultBytes():ByteArray{
			this._result.position = 0;
			return this._result;
		}
		
		public function parse(input:IDataInput):void{
			input.readBytes(_result,_result.length,input.bytesAvailable);
			
			var b:int;
			while(_result.bytesAvailable){
				b = _result.readByte();
				_line.writeByte(b);
				if( b == LF){
					_line.position = 0;
					var newLine:ByteArray = new ByteArray();
					_line.readBytes(newLine,0,_line.bytesAvailable);
					newLine.position = 0;
					_line.clear();
					_line.position = 0;
					var evt:TextStreamReaderEvent = new TextStreamReaderEvent(TextStreamReaderEvent.TEXT_STREAM_LINE);
					evt.lineBytes = newLine;
					this.dispatchEvent(evt);
				}
			}
		}
		
		public function clear():void{
			this._result = new ByteArray();
			this._line = new ByteArray();
		}
	}
}