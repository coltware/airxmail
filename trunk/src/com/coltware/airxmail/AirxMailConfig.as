/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail
{
	import com.coltware.airxlib.utils.ISO2022JPCode;
	import com.coltware.airxmail.encode.Base64;
	import com.coltware.airxmail.encode.IEncoder;
	import com.coltware.airxmail_internal;
	
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	use namespace airxmail_internal;
	
	/**
	 *  Default parameters class for airxmail
	 * 
	 */
	public class AirxMailConfig
	{
		//  default body charset
		private static var _default_body_charset:String = null;
		//  default header(subject,to,ftom etc...) charset
		private static var _default_header_charset:String = null;
		
		private static var _decodeDict:Dictionary = new Dictionary();
		
		/**
		 *  set default charset for body
		 *  
		 *  ex)
		 *  AirxMailConfig.setDefaultBodyCharset("ISO-2022-JP");
		 *  
		 *  "text/plain" -&lt; "text/plain; charset=ISO-2022-JP" 
		 */
		public static function setDefaultBodyCharset(str:String):void{
			if(str != null){
				_default_body_charset = str.toUpperCase();
			}
		}
		
		public static function setDefaultHeaderCharset(str:String):void{
			if(str != null){
				_default_header_charset = str.toUpperCase();
			}
		}
		
		public static function setDecodeCharetFunction(func:Function,charset:String):void{
			_decodeDict[charset] = func;
		}
		
		public static function getDecodeCharsetFunction(charset:String):Function{
			if(_decodeDict[charset]){
				return _decodeDict[charset] as Function;
			}
			else{
				return _readMultiByte;
			}
		}
		
		private static function _readMultiByte(bytes:ByteArray,charset:String):String{
			if(charset == "utf8"){
				charset = "utf-8";
			}
			
			if(charset == 'iso-2022-jp'){
				if(Capabilities.manufacturer.indexOf("Windows") == -1){
					var jis:ISO2022JPCode = new ISO2022JPCode();
					jis.dataInput = bytes;
					jis.read();
					return jis.toUTF8String();
				}
			}
			return bytes.readMultiByte(bytes.bytesAvailable,charset);
		}
		
		airxmail_internal static function get DEFAULT_BODY_CHARSET():String{
			if(_default_body_charset){
				return _default_body_charset;
			}
			if(Capabilities.language == "ja"){
				return "ISO-2022-JP";
			}
			else{
				return "UTF-8";
			}
		}
		
		airxmail_internal static function get DEFAULT_HEADER_CHARSET():String{
			if(_default_header_charset){
				return _default_header_charset;
			}
			if(Capabilities.language == "ja"){
				return "ISO-2022-JP";
			}
			else{
				return null;
			}
		}
		
		airxmail_internal static function get DEBUG():Boolean{
			return false;
		}
		
		airxmail_internal static function getEncoder(type:String):IEncoder{
			if(type == "base64"){
				return new Base64();
			}
			return null;
		}
	}
}