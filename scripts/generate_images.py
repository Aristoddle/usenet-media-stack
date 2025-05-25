#!/usr/bin/env python3
"""
AI Image Generation Service for Usenet Media Stack
Uses OpenAI GPT Image model to generate relevant visual assets
"""

import base64
import os
import sys
from io import BytesIO
from pathlib import Path

try:
    from openai import OpenAI
    from PIL import Image
except ImportError:
    print("Required packages not installed. Run: pip install openai pillow")
    sys.exit(1)

class UsenetImageGenerator:
    def __init__(self, api_key=None):
        """Initialize with API key from environment"""
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OpenAI API key required. Set OPENAI_API_KEY environment variable.")
        
        self.client = OpenAI(api_key=self.api_key)
        
        # Create images directory
        self.images_dir = Path(__file__).parent.parent / "docs" / "public" / "images" / "generated"
        self.images_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_image(self, prompt, filename, size="1024x1024", quality=80):
        """Generate image using OpenAI GPT Image model"""
        try:
            print(f"🎨 Generating image: {filename}")
            print(f"📝 Prompt: {prompt}")
            
            # Generate the image
            result = self.client.images.generate(
                model="gpt-image-1",
                prompt=prompt,
                size=size
            )
            
            # Get the base64 image data
            image_base64 = result.data[0].b64_json
            image_bytes = base64.b64decode(image_base64)
            
            # Open and resize for optimization
            image = Image.open(BytesIO(image_bytes))
            
            # Resize if needed (keep aspect ratio)
            if size != "1024x1024":
                width, height = map(int, size.split('x'))
                image = image.resize((width, height), Image.LANCZOS)
            
            # Save optimized image
            output_path = self.images_dir / filename
            image.save(output_path, format="JPEG", quality=quality, optimize=True)
            
            print(f"✅ Saved: {output_path}")
            return output_path
            
        except Exception as e:
            print(f"❌ Error generating {filename}: {e}")
            return None
    
    def generate_usenet_stack_images(self):
        """Generate all relevant images for the Usenet Media Stack"""
        
        images_to_generate = [
            {
                "filename": "hero-architecture.jpg",
                "prompt": "Modern software architecture diagram showing a hot-swappable media server stack with Docker containers, storage drives, and network connections. Professional technical illustration with blue and green color scheme, clean minimalist design, showing distributed services and data flow.",
                "size": "1792x1024"
            },
            {
                "filename": "hardware-optimization.jpg", 
                "prompt": "High-performance computer hardware setup with GPU acceleration, multiple storage drives, and server equipment. Professional technical photography style with dramatic lighting, showing NVIDIA RTX graphics card, multiple hard drives, and modern server components.",
                "size": "1024x1024"
            },
            {
                "filename": "storage-management.jpg",
                "prompt": "Professional visualization of hot-swappable storage system with multiple drives, JBOD arrays, and cloud storage connections. Technical diagram style showing drive discovery, mounting, and service integration with clean geometric design.",
                "size": "1024x1024"
            },
            {
                "filename": "media-automation.jpg",
                "prompt": "Media automation workflow showing movies, TV shows, books, and music being automatically organized and transcoded. Modern interface design with media thumbnails, quality profiles, and automation indicators in a professional dashboard style.",
                "size": "1024x1024"
            },
            {
                "filename": "service-topology.jpg",
                "prompt": "Network topology diagram showing 19+ microservices connected in a distributed system. Professional technical illustration with nodes, connections, and service dependencies visualized in a clean network graph style with modern color palette.",
                "size": "1024x1024"
            },
            {
                "filename": "cli-interface.jpg",
                "prompt": "Modern command-line interface showing advanced terminal commands and system management. Professional developer workspace with dark theme terminal, colorful output, and multiple command windows displaying system status and configuration.",
                "size": "1024x1024"
            },
            {
                "filename": "performance-metrics.jpg",
                "prompt": "Performance dashboard showing real-time system metrics, transcoding speeds, and hardware utilization. Professional monitoring interface with charts, graphs, and live data visualization in a modern dark theme.",
                "size": "1024x1024"
            },
            {
                "filename": "security-tunnel.jpg",
                "prompt": "Secure network tunnel visualization showing encrypted connections through Cloudflare with SSL/TLS protection. Professional cybersecurity illustration with lock icons, encrypted data streams, and secure network pathways.",
                "size": "1024x1024"
            }
        ]
        
        print("🚀 Starting AI image generation for Usenet Media Stack...")
        print(f"📁 Output directory: {self.images_dir}")
        
        results = []
        for image_config in images_to_generate:
            result = self.generate_image(**image_config)
            results.append(result)
        
        successful = len([r for r in results if r is not None])
        total = len(results)
        
        print(f"\n🎉 Generation complete: {successful}/{total} images created successfully")
        return results

def main():
    """Main entry point"""
    try:
        generator = UsenetImageGenerator()
        generator.generate_usenet_stack_images()
    except Exception as e:
        print(f"❌ Error: {e}")
        print("💡 Make sure to set OPENAI_API_KEY environment variable")
        sys.exit(1)

if __name__ == "__main__":
    main()