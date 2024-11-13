"""
Main entry point for the inspectomat.
"""

import click
import logging
import signal
import sys
from inspectomat import StreamFilterRouter, ManagedProcess

def signal_handler(signum, frame):
    """Handle shutdown signal by setting the global exit flag"""
    sys.exit(0)

@click.command()
@click.option('--flows-config', '-s', 
              default="config/flows.json",
              help="Path to flows configuration JSON file",
              type=click.Path(exists=True))
@click.option('--process-config', '-p',
              default="config/process.json",
              help="Path to process configuration JSON file",
              type=click.Path(exists=True))
def main(flows_config: str, process_config: str):
    """Main entry point for the inspectomat."""
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    router = StreamFilterRouter(flows_config, process_config)

    try:
        router.start()
        # Use signal.pause() instead of infinite loop
        signal.pause()
    except (KeyboardInterrupt, SystemExit):
        router.stop()
        logging.info("inspectomat shutdown complete")
        sys.exit(0)

if __name__ == "__main__":
    main()

# ffmpeg -i "rtsp://test1234:test1234@192.168.188.225:554/Preview_01_sub" -vf "format=rgb24,dlopen=esrgan.so:upscale:model=$3/ESRGAN.pb,scale=3840:2160:flags=lanczos" -c:v libx264 -preset slower -crf 20 -c:a copy -f segment -segment_time 300 -strftime 1 recognition/upscaled.mp4

 ffmpeg -i rtsp://test1234:test1234@192.168.188.225:554/Preview_01_sub -vf "format=rgb24,dlopen=recognition.so:detect:model=model://recognition/model.pb:labels=model://recognition/labels.txt,drawbox=enable='between(t,td_start,td_end)':x='xd':y='yd':w='wd':h='hd':color=yellow:thickness=2" -c:v libx264 -preset fast -crf 23 -f segment -segment_time 300 -strftime 1 ./recognition/tracked.mp4

ffmpeg -i rtsp://test1234:test1234@192.168.188.225:554/Preview_01_sub \
  -vf "format=rgb24,\
       dlopen=./recognition/recognition.so:detect:\
       model=./recognition/model.pb:\
       labels=./recognitionlabels.txt,\
       drawbox=enable='between(t,\${td_start},\${td_end})':\
       x=\${xd}:y=\${yd}:w=\${wd}:h=\${hd}:\
       color=yellow:thickness=2" \
  -c:v libx264 -preset fast -crf 23 \
  -f segment -segment_time 300 -strftime 1 \
  ./recognition/tracked.mp4

