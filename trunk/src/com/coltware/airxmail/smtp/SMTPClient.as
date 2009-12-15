/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.smtp
{
	import com.coltware.commons.job.SocketJobSync;
	import com.coltware.commons.utils.StringLineReader;
	import com.coltware.airxmail_internal;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.IDataInput;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.Base64Encoder;
	import mx.utils.StringUtil;
	
	use namespace airxmail_internal;
	
	/**
	 *  dataAsync()コマンドを投げてデータが書き出せる状態になったときのイベント
	 * 
	 * @eventType com.coltware.airxmail.smtp.SMTPEvent.ACCEPT_DATA
	 */
	[Event(name="smtpAcceptData",type="com.coltware.airxmail.smtp.SMTPEvent")]
	
	/**
	 *  SMTPレベルで接続ができなかったときのイベント.
	 * 
	 * メモ：Socketベースではありません。HELOもしくはEHLOを投げてエラーとなったときに発行されます。
	 * ただし、EHLOでESMTPをサポートしていないエラーはここに含まれません。
	 * 
	 * @eventType com.coltware.airxmail.smtp.SMTPEvent.SMTP_CONNECTION_FAILED
	 */
	[Event(name="smtpConnectionFailed",type="com.coltware.airxmail.smtp.SMTPEvent")]
	
	/**
	 *  EHLOコマンドを投げてESMTPをサポートしていなかったときに発行されます。
	 *
	 *  メモ：このエラーエベントはehlo(hostname,autoSMTP=true)としても発行されます。
	 *  ただし、この自動的にautoSMTP=trueの場合にはHELOコマンドを投げますので、何も処理しなくても問題ありません。
	 * 
	 * @eventType com.coltware.airxmail.smtp.SMTPEvent.NOT_SUPPORT_ESMTP;
	 */
	[Event(name="smtpNotSupportESMTP",type="com.coltware.airxmail.smtp.SMTPEvent")]
	/**
	 *  EHLOコマンドを投げてESMTPをサポートしていなかったときに発行されます。
	 *
	 *  メモ：このエラーエベントはehlo(hostname,autoSMTP=true)としても発行されます。
	 *  ただし、この自動的にautoSMTP=trueの場合にはHELOコマンドを投げますので、何も処理しなくても問題ありません。
	 * 
	 * @eventType com.coltware.airxmail.smtp.SMTPEvent.NOT_SUPPORT_ESMTP;
	 */
	[Event(name="smtpNoopOk",type="com.coltware.airxmail.smtp.SMTPEvent")]
	
	/**
	 *  SMTPのプロトコルを処理するためのクラス
	 * 
	 */
	public class SMTPClient extends SocketJobSync
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxmail.smtp.SMTPClient");
		
		private var _lineReader:StringLineReader;
		
		/**
		 * ESMTPをサポートするか
		 */
		private var _supportESMTP:Boolean = false;
		
		private var _auth:Boolean = false;
		private var _authType:String = "";
		//  認証が可能か（ユーザ名とパスワードが設定されているか？)
		private var _enableAuth:Boolean = false;
		
		private var _username:String = null;
		private var _password:String = null;
		
		private var CMD_TYPE_DATA_ASYNC:int = 100;
		/**
		 *  認証フェーズのタイプ
		 */
		private var CMD_TYPE_AUTH_SESS:int  = 200;
		
		public function SMTPClient()
		{
			super();
			_lineReader = new StringLineReader();
			this.port = 25;
		}
		
		/**
		 * 認証を可能にする
		 */
		public function setAuth(username:String,password:String):void{
			log.info("enable auth : " + username);
			_username = username;
			_password = password;
			this._enableAuth = true;
		}
		
		/**
		 * 接続された状態か?
		 */
		public function get isConnected():Boolean{
			if(this._sock){
				return this._isConnected;
				//return this._sock.connected;
			}
			return false;
		}
		
		/**
		 * HELOコマンド
		 */
		public function helo(myhost:String):void{
			var cmd:Object = new Object;
			cmd.key = "HELO";
			cmd.value = myhost;
			this.addJob(cmd);
		}
		/**
		 *  EHLOコマンド
		 *  
		 *  @param autoESMTP ESMTPが利用できない場合には自動的にHELOにする
		 * 
		 */
		public function ehlo(myhost:String,autoESMTP:Boolean = true):void{
			var cmd:Object = new Object();
			cmd.key = "EHLO";
			cmd.type = 0;
			cmd.value = myhost;
			cmd.auto = autoESMTP;
			this.addJob(cmd);
		}
		/**
		 * MAIL FROMコマンド
		 */
		public function mailFrom(from:String):void{
			var cmd:Object = new Object();
			cmd.key = "MAIL FROM:";
			cmd.type = 0;
			if(from.charAt(0) != "<"){
				cmd.value = "<" + from + ">";
			}
			else{
				cmd.value = from;
			}
			this.addJob(cmd);
		}
		/**
		 *  RCPT TO コマンド
		 */
		public function rcptTo(email:String):void{
			var cmd:Object = new Object();
			cmd.key = "RCPT TO:";
			cmd.type = 0;
			if(email.charAt(0) == "<"){
				cmd.value = email;
			}
			else{
				cmd.value = "<" + email + ">";
			}
			this.addJob(cmd);
		}
		/**
		 *  NOOPコマンド
		 *  (何もしないためのコマンド。応答を確認する)
		 */
		public function noop():void{
			var cmd:Object = new Object();
			cmd.key = "NOOP";
			cmd.type = 0;
			this.addJob(cmd);
		}
		/**
		 *  データを送信する
		 *  最後の<CR><LF>.<CR><LF>はなくてよい
		 */
		public function data(data:String):void{
			var cmd:Object = new Object();
			cmd.key = "DATA";
			cmd.type = 1;
			this.addJob(cmd);
			
			var cmd2:Object = new Object();
			cmd2.type = 2;
			cmd2.key = "DATA";
			cmd2.value = data + "\r\n.\r\n";
			this.addJob(cmd2);
		}
		
		/**
		 *  データを送信する
		 *  大きなデータを送るときになどにこちらを利用する。
		  *  　準備が完了するとイベントを発行するので、そのイベントで処理をする　 
		 */
		public function dataAsync():void{
			var cmd:Object = new Object();
			cmd.key = "DATA";
			cmd.type = CMD_TYPE_DATA_ASYNC;
			this.addJob(cmd);
		}
		
		public function quit():void{
			var cmd:Object = new Object();
			cmd.key = "QUIT";
			cmd.type = 0;
			this.addJob(cmd);
		}
		
		/**
		 * 内部向けにLOGINを自動的に行う
		 */
		private function authPlain(insert:Boolean = false):void{
			var step1:Object = new Object();
			step1.key = "AUTH";
			step1.value = "LOGIN";
			step1.type = CMD_TYPE_AUTH_SESS;
			step1.onlyValue = false;
			
			var base64:Base64Encoder = new Base64Encoder();
			
			
			var step2:Object = new Object();
			step2.type = CMD_TYPE_AUTH_SESS;
			step2.key = "USERNAME";
			base64.encodeUTFBytes(this._username);
			step2.value = base64.toString();
			step2.onlyValue = true;
			base64.reset();
			
			var step3:Object = new Object();
			step3.type = CMD_TYPE_AUTH_SESS;
			step3.key = "PASSWORD";
			base64.encodeUTFBytes(this._password);
			step3.value = base64.toString();
			step3.onlyValue = true;
			
			if(insert){
				this.addJobAt(step1,0);
				this.addJobAt(step2,1);
				this.addJobAt(step3,2);
			}
			else{
				this.addJob(step1);
				this.addJob(step2);
				this.addJob(step3);
			}
		}
		
		override protected function exec(job:Object):void{
			if(job.type < 2 ){
				var line:String = job.key;
				if(job["value"]){
					line += " " + job["value"];
				}
				log.debug(line);
				this._sock.writeUTFBytes(line + "\r\n");
				this._sock.flush();
			}
			else if(job.type == CMD_TYPE_DATA_ASYNC){
				this._sock.writeUTFBytes("DATA\r\n");
				this._sock.flush();
			}
			else if(job.type == CMD_TYPE_AUTH_SESS){
				if(job.onlyValue){
					log.debug("WRITE V:" + job.value);
					this._sock.writeUTFBytes(job.value + "\r\n");
					this._sock.flush();
				}
				else{
					log.debug("WRITE KV:" + job.key + " " + job.value + ":" + job.onlyValue); 
					this._sock.writeUTFBytes(job.key + " " + job.value + "\r\n");
					this._sock.flush();
				}
			}
			else{
				log.debug("WRITE:" + job.value);
				this._sock.writeUTFBytes(job.value + "\r\n");
				this._sock.flush();
			}
		}
		
		override protected function handleData(pe:ProgressEvent):void{
			var ret:String;
			if(this.isServiceReady){
				if(this.currentJob){
					var cmd:String = this.currentJob.key;
					
					_lineReader.source = IDataInput(_sock);
					var line:String = null;
					var code:String = null;
					if(this.currentJob.type == 0 ){
							var quit:Boolean = false;
							while(line = _lineReader.next()){
								code = line.substr(0,4);
								code = StringUtil.trim(code);
								log.debug("[" + cmd +  "]:" + StringUtil.trim(line));
								if(cmd == "EHLO"){
									var auth:int = line.indexOf("AUTH");
									if(auth > 0){
										this._auth = true;
										log.info("need auth : " + line);
										// タイプをみる		
										if(line.indexOf("PLAIN") > 0){
											this._authType = "PLAIN";
										}
									}
								}
								
								if(code == "250"){
									if(cmd == "EHLO"){
										this._supportESMTP = true;
										
										//  認証が必要で、認証用のIDとパスワードが設定されているとき
										if(this._auth && this._enableAuth){
											if(this._authType == "PLAIN"){
												this.authPlain(true);
											}
											else{
												//  NOT SUPPORT
												log.error("not support auth type : " + this._authType);
											}
										}
										
									}
									else if(cmd == "NOOP"){
										var noopEvent:SMTPEvent = new SMTPEvent(SMTPEvent.SMTP_NOOP_OK);
										this.dispatchEvent(noopEvent);
									}
									this.commitJob();
								}
								else if(code == "250-"){
									// 次の行への情報
								}
								else{
									if(cmd == "QUIT" && code == "221"){
										log.info("QUIT Completed ..");
										quit = true;
										this.commitJob();
									}
									else if(cmd == "EHLO" && code == "502"){
										var evt:SMTPEvent = new SMTPEvent(SMTPEvent.SMTP_NOT_SUPPORT_ESMTP);
										this.dispatchEvent(evt);
										if(this.currentJob.auto){
											var nj:Object = new Object();
											nj.key = "HELO";
											nj.value = this.currentJob.value;
											nj.type  = this.currentJob.type;
											this.currentJob = nj;
											this.exec(nj);
										}
										else{
											this.commitJob();
										}
									}
								}
							}
							if(quit){
								log.debug("disconnecting ...");
								this.disconnect();
							}
					}
					else if(this.currentJob.type == 1){
						// DATA コマンド
						while(line = _lineReader.next()){
							log.debug("[" + cmd +  "]:" + StringUtil.trim(line));
							code = line.substr(0,4);
							code = StringUtil.trim(code);
							if(code == "354"){
								this.commitJob();
							}
						}
					}
					else if(this.currentJob.type == CMD_TYPE_DATA_ASYNC){
						// DATA コマンド
						while(line = _lineReader.next()){
							log.debug("[" + cmd +  "]:" + StringUtil.trim(line));
							code = line.substr(0,4);
							code = StringUtil.trim(code);
							if(code == "354"){
								//  イベントを発行する
								var smtpEvent:SMTPEvent = new SMTPEvent(SMTPEvent.SMTP_ACCEPT_DATA);
								smtpEvent.$sock = this._sock;
								this.dispatchEvent(smtpEvent);
							}
							else if(code == "250"){
								this.commitJob();
							}
						}
					}
					else if(this.currentJob.type == CMD_TYPE_AUTH_SESS){
						//  認証中
						while(line = _lineReader.next()){
							log.debug("[" + cmd +  "]:" + StringUtil.trim(line));
							code = line.substr(0,4);
							code = StringUtil.trim(code);
							if(code == "334"){
								this.commitJob();
							}
							else if(code == "235"){
								this.commitJob();
							}
						}
					}
					else{
						while(line = _lineReader.next()){
							log.debug("[" + cmd +  "]:" + StringUtil.trim(line));
							code = line.substr(0,4);
							code = StringUtil.trim(code);
							if(code == "250"){
								this.commitJob();
							}
						}
					}
					 
				}
				else{
					ret = _sock.readUTFBytes(_sock.bytesAvailable);
					log.debug("[nojob] " + ret); 
				}
			}
			else{
				log.debug("no ready...");
				ret = _sock.readUTFBytes(_sock.bytesAvailable);
				var readyCode:String = ret.substr(0,3);
				if(readyCode == "220"){
					log.debug("[SMTP]" + StringUtil.trim(ret));
					//  サービスの準備ＯＫ
					this.serviceReady();
				}
				else{
					var smtpConnFailedEvent:SMTPEvent = new SMTPEvent(SMTPEvent.SMTP_CONNECTION_FAILED,true);
					this.dispatchEvent(smtpConnFailedEvent);
				}
			}
			
		}
		
		override protected function ioerrorHandler(io:IOErrorEvent):void{
			this.fireConnectionFailed();
		}
		
		override protected function socketClosing(e:Event):void{
			super.socketClosing(e);
			if(!this.isServiceReady){
				this.fireConnectionFailed();
			}
		}
		
		/**
		 * @private
		 */
		protected function fireConnectionFailed():void{
			//  サービスの準備ができないまま、サーバからの切断なので
			var event:SMTPEvent = new SMTPEvent(SMTPEvent.SMTP_CONNECTION_FAILED);
			this.dispatchEvent(event);
		}
		
		
	}
}