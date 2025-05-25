#!/usr/bin/env python3
"""
MCP (Model Context Protocol) Server for Usenet Media Stack
Provides AI integration and tool calling capabilities
"""

import json
import sys
import asyncio
from typing import Dict, Any, List
import logging

# MCP server implementation
class UsenetMCPServer:
    def __init__(self):
        self.tools = {}
        self.setup_tools()
        
    def setup_tools(self):
        """Setup available MCP tools"""
        self.tools = {
            "generate_image": {
                "name": "generate_image",
                "description": "Generate AI images for documentation and visual assets",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "prompt": {"type": "string", "description": "Image generation prompt"},
                        "filename": {"type": "string", "description": "Output filename"},
                        "size": {"type": "string", "description": "Image size (e.g., 1024x1024)"}
                    },
                    "required": ["prompt", "filename"]
                }
            },
            "get_system_status": {
                "name": "get_system_status", 
                "description": "Get current system status and service health",
                "inputSchema": {
                    "type": "object",
                    "properties": {},
                    "required": []
                }
            },
            "discover_storage": {
                "name": "discover_storage",
                "description": "Discover and list available storage drives",
                "inputSchema": {
                    "type": "object", 
                    "properties": {},
                    "required": []
                }
            },
            "detect_hardware": {
                "name": "detect_hardware",
                "description": "Detect hardware capabilities and optimization opportunities",
                "inputSchema": {
                    "type": "object",
                    "properties": {},
                    "required": []
                }
            }
        }
    
    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP requests"""
        method = request.get("method")
        params = request.get("params", {})
        
        if method == "initialize":
            return {
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {"listChanged": True}
                    },
                    "serverInfo": {
                        "name": "usenet-media-stack",
                        "version": "1.0.0"
                    }
                }
            }
        
        elif method == "tools/list":
            return {
                "jsonrpc": "2.0", 
                "id": request.get("id"),
                "result": {
                    "tools": list(self.tools.values())
                }
            }
        
        elif method == "tools/call":
            tool_name = params.get("name")
            arguments = params.get("arguments", {})
            
            if tool_name == "generate_image":
                result = await self.generate_image(arguments)
            elif tool_name == "get_system_status":
                result = await self.get_system_status()
            elif tool_name == "discover_storage":
                result = await self.discover_storage()
            elif tool_name == "detect_hardware":
                result = await self.detect_hardware()
            else:
                result = {"error": f"Unknown tool: {tool_name}"}
            
            return {
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(result, indent=2)
                        }
                    ]
                }
            }
        
        else:
            return {
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "error": {
                    "code": -32601,
                    "message": f"Method not found: {method}"
                }
            }
    
    async def generate_image(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Generate image using AI"""
        import subprocess
        
        try:
            api_key = "ensk-proj-X66QlUj UWzWuG-EQdDQZsPv8G6WogtBmFc_PwdzQTHYkp-NHDrP7-eRFfLZW6VJW_nemJP7YCoT3BlbkFJlrmnNyDop2mkwtogG3SNTky-W69b5xrG1dIIeafcPGObovSJfh3o8Rm2A7HqiCIGac_ScsZAUA"
            
            cmd = [
                sys.executable, 
                "/home/joe/usenet/scripts/generate_images.py",
                api_key
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else None
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def get_system_status(self) -> Dict[str, Any]:
        """Get system status"""
        import subprocess
        
        try:
            # Check Docker services
            result = subprocess.run(
                ["docker", "compose", "ps", "--format", "json"],
                cwd="/home/joe/usenet",
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                services = json.loads(result.stdout) if result.stdout else []
                return {
                    "services": len(services),
                    "status": "running" if services else "stopped",
                    "details": services
                }
            else:
                return {"status": "error", "error": result.stderr}
                
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def discover_storage(self) -> Dict[str, Any]:
        """Discover storage drives"""
        import subprocess
        
        try:
            result = subprocess.run(
                ["/home/joe/usenet/usenet", "storage", "discover"],
                capture_output=True,
                text=True
            )
            
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else None
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def detect_hardware(self) -> Dict[str, Any]:
        """Detect hardware capabilities"""
        import subprocess
        
        try:
            result = subprocess.run(
                ["/home/joe/usenet/usenet", "hardware", "detect"],
                capture_output=True,
                text=True
            )
            
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else None
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

async def main():
    """Main MCP server entry point"""
    server = UsenetMCPServer()
    
    # Set up logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    
    logger.info("🚀 Starting Usenet MCP Server on port 8811")
    
    try:
        while True:
            # Read request from stdin
            line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            if not line:
                break
                
            try:
                request = json.loads(line.strip())
                response = await server.handle_request(request)
                print(json.dumps(response))
                sys.stdout.flush()
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON: {line}")
            except Exception as e:
                logger.error(f"Error handling request: {e}")
                
    except KeyboardInterrupt:
        logger.info("🛑 Server shutting down")

if __name__ == "__main__":
    asyncio.run(main())