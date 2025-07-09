# 🧪 Local Stack Validation

This guide shows how to spin up the Usenet Media Stack locally and
run the Playwright-based validation script.

## Requirements

- Docker and Docker Compose
- Node.js 18+

## Steps

1. Install dependencies:

   ```bash
   npm ci
   npx playwright install --with-deps
   ```

2. Start the stack:

   ```bash
   docker compose up -d
   ```

3. Run the validation script:

   ```bash
   node validate-services.js
   ```

   Screenshots are saved to `validation-screenshots/` and results to
   `validation-results.json`.

4. Stop the stack when done:

   ```bash
   docker compose down
   ```
