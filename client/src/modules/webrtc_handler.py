# WebRTC Stream Handler for Real-time Video Streaming

import asyncio
import json
import logging
import time
import base64
from datetime import datetime
import threading
import queue

try:
    import websocket
    import ssl
    WEBSOCKET_AVAILABLE = True
except ImportError:
    WEBSOCKET_AVAILABLE = False
    logging.warning("websocket-client not available, WebRTC fallback disabled")

class WebRTCStreamHandler:
    def __init__(self, api_client, client_id):
        self.api_client = api_client
        self.client_id = client_id
        self.is_streaming = False
        self.websocket = None
        self.websocket_thread = None
        self.message_queue = queue.Queue()
        
        # Enhanced logging
        self.logger = logging.getLogger(f"WebRTCHandler-{client_id}")
        
        # WebRTC configuration
        self.ice_servers = [
            {"urls": "stun:stun.l.google.com:19302"},
            {"urls": "stun:stun1.l.google.com:19302"}
        ]
        
        # Stream statistics
        self.frames_sent = 0
        self.bytes_sent = 0
        self.connection_start_time = None
        
    def is_available(self):
        """Check if WebRTC streaming is available"""
        return WEBSOCKET_AVAILABLE
    
    def start_streaming(self, quality='medium'):
        """Start WebRTC streaming"""
        if not self.is_available():
            self.logger.error("WebRTC not available - websocket-client missing")
            return False
            
        if self.is_streaming:
            self.logger.warning("WebRTC streaming already active")
            return True
            
        try:
            self.logger.info("=== WEBRTC STREAMING STARTING ===")
            self.is_streaming = True
            self.connection_start_time = time.time()
            
            # Start WebSocket connection in separate thread
            self.websocket_thread = threading.Thread(
                target=self._websocket_worker,
                daemon=True,
                name=f"WebRTC-{self.client_id}"
            )
            self.websocket_thread.start()
            
            self.logger.info("WebRTC streaming started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start WebRTC streaming: {e}")
            self.is_streaming = False
            return False
    
    def stop_streaming(self):
        """Stop WebRTC streaming"""
        self.logger.info("=== STOPPING WEBRTC STREAMING ===")
        self.is_streaming = False
        
        if self.websocket:
            try:
                self.websocket.close()
            except Exception as e:
                self.logger.error(f"Error closing WebSocket: {e}")
        
        if self.websocket_thread and self.websocket_thread.is_alive():
            self.websocket_thread.join(timeout=5)
            
        # Log statistics
        if self.connection_start_time:
            uptime = time.time() - self.connection_start_time
            avg_fps = self.frames_sent / max(1, uptime)
            self.logger.info(f"WebRTC session ended: {self.frames_sent} frames, "
                           f"{self.bytes_sent} bytes, {uptime:.1f}s, avg FPS: {avg_fps:.1f}")
    
    def send_frame(self, frame_data, sequence=0):
        """Send video frame via WebRTC"""
        if not self.is_streaming or not self.websocket:
            return False
            
        try:
            # Encode frame data
            encoded_frame = base64.b64encode(frame_data).decode('utf-8')
            
            message = {
                'type': 'video_frame',
                'client_id': self.client_id,
                'sequence': sequence,
                'timestamp': time.time(),
                'data': encoded_frame
            }
            
            # Add to message queue for WebSocket thread
            self.message_queue.put(json.dumps(message))
            
            # Update statistics
            self.frames_sent += 1
            self.bytes_sent += len(frame_data)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error sending WebRTC frame: {e}")
            return False
    
    def _websocket_worker(self):
        """WebSocket worker thread for WebRTC signaling"""
        try:
            # Construct WebSocket URL
            base_url = self.api_client.server_url.replace('http://', 'ws://').replace('https://', 'wss://')
            ws_url = f"{base_url}/ws/stream/{self.client_id}"
            
            self.logger.info(f"Connecting to WebSocket: {ws_url}")
            
            # Create WebSocket connection
            self.websocket = websocket.WebSocketApp(
                ws_url,
                on_open=self._on_websocket_open,
                on_message=self._on_websocket_message,
                on_error=self._on_websocket_error,
                on_close=self._on_websocket_close
            )
            
            # Run WebSocket client
            self.websocket.run_forever(
                ping_interval=30,
                ping_timeout=10,
                sslopt={"cert_reqs": ssl.CERT_NONE} if 'wss://' in ws_url else None
            )
            
        except Exception as e:
            self.logger.error(f"WebSocket worker failed: {e}")
        finally:
            self.is_streaming = False
    
    def _on_websocket_open(self, ws):
        """WebSocket connection opened"""
        self.logger.info("WebSocket connection established")
        
        # Send initialization message
        init_message = {
            'type': 'client_init',
            'client_id': self.client_id,
            'timestamp': time.time()
        }
        
        ws.send(json.dumps(init_message))
        
        # Start message sender thread
        sender_thread = threading.Thread(target=self._message_sender, daemon=True)
        sender_thread.start()
    
    def _on_websocket_message(self, ws, message):
        """Handle WebSocket message"""
        try:
            data = json.loads(message)
            msg_type = data.get('type')
            
            if msg_type == 'ping':
                # Respond to server ping
                ws.send(json.dumps({'type': 'pong', 'timestamp': time.time()}))
            elif msg_type == 'quality_change':
                # Handle quality change request
                new_quality = data.get('quality', 'medium')
                self.logger.info(f"Server requested quality change: {new_quality}")
            else:
                self.logger.debug(f"Received WebSocket message: {msg_type}")
                
        except Exception as e:
            self.logger.error(f"Error handling WebSocket message: {e}")
    
    def _on_websocket_error(self, ws, error):
        """WebSocket error handler"""
        self.logger.error(f"WebSocket error: {error}")
    
    def _on_websocket_close(self, ws, close_status_code, close_msg):
        """WebSocket connection closed"""
        self.logger.info(f"WebSocket connection closed: {close_status_code} - {close_msg}")
        self.is_streaming = False
    
    def _message_sender(self):
        """Send queued messages to WebSocket"""
        while self.is_streaming and self.websocket:
            try:
                # Get message from queue with timeout
                message = self.message_queue.get(timeout=1)
                
                if self.websocket and self.is_streaming:
                    self.websocket.send(message)
                    
            except queue.Empty:
                continue
            except Exception as e:
                self.logger.error(f"Error sending WebSocket message: {e}")
                break
    
    def get_statistics(self):
        """Get WebRTC streaming statistics"""
        if not self.connection_start_time:
            return None
            
        uptime = time.time() - self.connection_start_time
        return {
            'uptime': uptime,
            'frames_sent': self.frames_sent,
            'bytes_sent': self.bytes_sent,
            'avg_fps': self.frames_sent / max(1, uptime),
            'is_streaming': self.is_streaming
        }
