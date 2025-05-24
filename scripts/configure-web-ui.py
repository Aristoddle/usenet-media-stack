#!/usr/bin/env python3
"""
Web UI Configuration Script for Usenet Stack
Uses Playwright to automate browser-based setup wizards and configuration
"""

import asyncio
import json
import os
import sys
from typing import Dict, List, Optional
from playwright.async_api import async_playwright, Browser, Page

# Service configurations
SERVICES = {
    "sabnzbd": {
        "url": "http://localhost:8080",
        "wizard_steps": [
            {"action": "select_language", "value": "en"},
            {"action": "set_server_details", "host": "0.0.0.0", "port": "8080"},
            {"action": "skip_authentication"},  # For local-only access
            {"action": "complete_wizard"}
        ],
        "providers": [
            {
                "name": "Newshosting",
                "host": "news.newshosting.com",
                "port": "563",
                "username": "j3lanzone@gmail.com",
                "password": "@Kirsten123",
                "connections": "30",
                "ssl": True
            },
            {
                "name": "UsenetExpress",
                "host": "usenetexpress.com",
                "port": "563",
                "username": "une3226253",
                "password": "kKqzQXPeN",
                "connections": "20",
                "ssl": True
            },
            {
                "name": "Frugalusenet",
                "host": "newswest.frugalusenet.com",
                "port": "563",
                "username": "aristoddle",
                "password": "fishing123",
                "connections": "10",
                "ssl": True
            }
        ],
        "categories": ["tv", "movies", "books", "comics", "music"]
    },
    "prowlarr": {
        "url": "http://localhost:9696",
        "indexers": [
            {"name": "NZBgeek", "type": "newznab", "url": "https://api.nzbgeek.info", "apikey": "SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a"},
            {"name": "NZBFinder", "type": "newznab", "url": "https://nzbfinder.ws", "apikey": "14b3d53dbd98adc79fed0d336998536a"},
            {"name": "NZBsu", "type": "newznab", "url": "https://api.nzb.su", "apikey": "25ba450623c248e2b58a3c0dc54aa019"},
            {"name": "NZBPlanet", "type": "newznab", "url": "https://api.nzbplanet.net", "apikey": "046863416d824143c79b6725982e293d"}
        ]
    },
    "sonarr": {
        "url": "http://localhost:8989",
        "root_folder": "/tv",
        "download_client": "sabnzbd",
        "category": "tv"
    },
    "radarr": {
        "url": "http://localhost:7878",
        "root_folder": "/movies",
        "download_client": "sabnzbd",
        "category": "movies"
    },
    "readarr": {
        "url": "http://localhost:8787",
        "root_folder": "/books",
        "download_client": "sabnzbd",
        "category": "books"
    },
    "bazarr": {
        "url": "http://localhost:6767",
        "sonarr_connection": True,
        "radarr_connection": True
    }
}

class UsenetConfigurator:
    def __init__(self, headless: bool = True):
        self.headless = headless
        self.browser: Optional[Browser] = None
        
    async def start(self):
        """Start the browser"""
        playwright = await async_playwright().start()
        self.browser = await playwright.chromium.launch(headless=self.headless)
        
    async def stop(self):
        """Stop the browser"""
        if self.browser:
            await self.browser.close()
            
    async def configure_sabnzbd(self, page: Page) -> bool:
        """Configure SABnzbd through web UI"""
        try:
            print("Configuring SABnzbd...")
            await page.goto(SERVICES["sabnzbd"]["url"])
            
            # Check if wizard is active
            if "wizard" in page.url:
                print("SABnzbd wizard detected, completing setup...")
                
                # Step 1: Language selection
                await page.wait_for_selector('input[name="lang"]')
                await page.click('input[id="en"]')
                await page.click('button:has-text("Start Wizard")')
                
                # Step 2: Server configuration
                await page.wait_for_selector('input[name="host"]')
                await page.fill('input[name="host"]', '0.0.0.0')
                await page.click('button:has-text("Next")')
                
                # Step 3: Authentication (skip for local access)
                await page.wait_for_selector('input[name="username"]')
                # Leave empty for no authentication on local network
                await page.click('button:has-text("Next")')
                
                # Step 4: Complete wizard
                await page.wait_for_selector('button:has-text("Go to SABnzbd")')
                await page.click('button:has-text("Go to SABnzbd")')
                
            # Wait for main interface
            await page.wait_for_selector('.navbar', timeout=10000)
            
            # Go to Config > Servers
            await page.click('a:has-text("Config")')
            await page.click('a:has-text("Servers")')
            
            # Add each provider
            for provider in SERVICES["sabnzbd"]["providers"]:
                print(f"Adding provider: {provider['name']}")
                await page.click('button:has-text("Add Server")')
                
                await page.fill('input[name="server"]', provider['host'])
                await page.fill('input[name="port"]', provider['port'])
                await page.fill('input[name="username"]', provider['username'])
                await page.fill('input[name="password"]', provider['password'])
                await page.fill('input[name="connections"]', provider['connections'])
                
                if provider['ssl']:
                    await page.check('input[name="ssl"]')
                    
                await page.click('button:has-text("Save")')
                await asyncio.sleep(1)
                
            # Configure categories
            await page.click('a:has-text("Categories")')
            for category in SERVICES["sabnzbd"]["categories"]:
                print(f"Adding category: {category}")
                await page.fill(f'input[name="{category}_dir"]', f"{category}")
                
            await page.click('button:has-text("Save")')
            
            print("SABnzbd configuration complete!")
            return True
            
        except Exception as e:
            print(f"Error configuring SABnzbd: {e}")
            return False
            
    async def configure_prowlarr(self, page: Page) -> bool:
        """Configure Prowlarr indexers"""
        try:
            print("Configuring Prowlarr...")
            await page.goto(SERVICES["prowlarr"]["url"])
            
            # Skip authentication setup if prompted
            if "authentication" in page.url.lower():
                await page.click('button:has-text("Skip")')
                
            # Wait for main interface
            await page.wait_for_selector('.navbar', timeout=10000)
            
            # Go to Settings > Indexers
            await page.click('a:has-text("Settings")')
            await page.click('a:has-text("Indexers")')
            
            # Add each indexer
            for indexer in SERVICES["prowlarr"]["indexers"]:
                print(f"Adding indexer: {indexer['name']}")
                await page.click('button:has-text("+")')
                
                # Search for Newznab
                await page.fill('input[placeholder="Search"]', 'newznab')
                await page.click('div:has-text("Generic Newznab")')
                
                # Fill in details
                await page.fill('input[name="name"]', indexer['name'])
                await page.fill('input[name="url"]', indexer['url'])
                await page.fill('input[name="apiKey"]', indexer['apikey'])
                
                # Test and save
                await page.click('button:has-text("Test")')
                await page.wait_for_selector('div:has-text("Test successful")')
                await page.click('button:has-text("Save")')
                await asyncio.sleep(1)
                
            print("Prowlarr configuration complete!")
            return True
            
        except Exception as e:
            print(f"Error configuring Prowlarr: {e}")
            return False
            
    async def configure_arr_app(self, page: Page, app_name: str) -> bool:
        """Configure Sonarr/Radarr/Readarr apps"""
        try:
            print(f"Configuring {app_name}...")
            config = SERVICES[app_name]
            await page.goto(config["url"])
            
            # Skip authentication if prompted
            if "authentication" in page.url.lower():
                await page.click('button:has-text("Skip")')
                
            # Wait for main interface
            await page.wait_for_selector('.navbar', timeout=10000)
            
            # Add root folder
            await page.click('a:has-text("Settings")')
            await page.click('a:has-text("Media Management")')
            await page.click('button:has-text("Add Root Folder")')
            await page.fill('input[name="path"]', config["root_folder"])
            await page.click('button:has-text("OK")')
            
            # Add download client (SABnzbd)
            await page.click('a:has-text("Download Clients")')
            await page.click('button:has-text("+")')
            await page.click('div:has-text("SABnzbd")')
            
            await page.fill('input[name="host"]', 'localhost')
            await page.fill('input[name="port"]', '8080')
            await page.fill('input[name="category"]', config["category"])
            
            await page.click('button:has-text("Test")')
            await page.wait_for_selector('div:has-text("Test successful")')
            await page.click('button:has-text("Save")')
            
            # Connect to Prowlarr
            await page.click('a:has-text("Indexers")')
            await page.click('button:has-text("+")')
            await page.click('div:has-text("Add Prowlarr")')
            
            await page.fill('input[name="host"]', 'localhost')
            await page.fill('input[name="port"]', '9696')
            
            await page.click('button:has-text("Test")')
            await page.wait_for_selector('div:has-text("Test successful")')
            await page.click('button:has-text("Save")')
            
            print(f"{app_name} configuration complete!")
            return True
            
        except Exception as e:
            print(f"Error configuring {app_name}: {e}")
            return False
            
    async def run(self):
        """Run the full configuration process"""
        await self.start()
        
        try:
            # Create browser context
            context = await self.browser.new_context()
            page = await context.new_page()
            
            # Configure each service
            results = {
                "sabnzbd": await self.configure_sabnzbd(page),
                "prowlarr": await self.configure_prowlarr(page),
                "sonarr": await self.configure_arr_app(page, "sonarr"),
                "radarr": await self.configure_arr_app(page, "radarr"),
                "readarr": await self.configure_arr_app(page, "readarr")
            }
            
            # Print summary
            print("\n=== Configuration Summary ===")
            for service, success in results.items():
                status = "✓" if success else "✗"
                print(f"{status} {service}")
                
            await context.close()
            
        finally:
            await self.stop()

async def main():
    # Check if running in headless mode
    headless = "--headless" in sys.argv
    
    configurator = UsenetConfigurator(headless=headless)
    await configurator.run()

if __name__ == "__main__":
    asyncio.run(main())