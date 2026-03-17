# Deploy Checklist (FTP)

This checklist is for the current manual FTP deployment flow of BlendBarometer.

## 1. Before Upload (local)

1. Ensure your working tree is clean and tested.
2. Prepare a deployment payload (removes dev-only files):

```bash
bash scripts/prepare-deploy.sh
```

1. Optional: run the cleanup test script:

```bash
bash tests/deploy/test-prepare-deploy.sh
```

## 2. Upload

1. Upload the prepared payload to the server (FileZilla or script).
2. If using the script, provide env vars and run:

```bash
bash scripts/deploy-upload.sh
```

## 3. Server Requirements

1. Keep a server-side `.env` file (do not upload local `.env`).
2. Confirm at least:
   - `APP_ENV=production`
   - `APP_DEBUG=false`
   - Correct `APP_URL`, `DB_*`, `MAIL_*`
3. Ensure these are writable by the web server user:
   - `storage/`
   - `bootstrap/cache/`

## 4. After Upload (with SSH)

Run these on the server from project root:

```bash
php artisan down
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link
php artisan queue:restart
php artisan up
```

Notes:

- `php artisan storage:link` is only required once, but safe to rerun.
- `php artisan queue:restart` is only needed when queues are used.

## 5. If You Do NOT Have SSH

1. Build locally before upload:

```bash
composer install --no-dev --optimize-autoloader
npm ci
npm run build
```

1. Upload built assets and dependencies as part of payload:
   - `vendor/`
   - `public/build/`
2. You cannot run migrations/cache refresh commands without SSH or a hosting control panel tool.

## 6. Post-Deploy Verification

1. Open homepage and one form flow end-to-end.
2. Verify report/image generation works.
3. Check `storage/logs/laravel.log` for new errors.
4. If app is down, run:

```bash
php artisan up
```
